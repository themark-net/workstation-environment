#!/usr/bin/env python3
"""Thin attestor — challenge/response device trust (backend-pluggable).

Client contract (stable):
  POST /v1/enroll     → device_id + device_secret (once)
  POST /v1/challenge  → challenge_id + nonce
  POST /v1/attest     → ticket (after backend verifies evidence)
  POST /v1/verify_ticket
  GET  /healthz

Evidence backends (server-side only):
  LTZ_ATTESTOR_BACKEND=local|maa
"""
from __future__ import annotations

import hashlib
import hmac
import json
import os
import secrets
import time
import uuid
from pathlib import Path

from flask import Flask, jsonify, request

from backends import VerificationError, load_backend

app = Flask(__name__)

TTL = int(os.environ.get("LTZ_ATTESTOR_TOKEN_TTL", "3600"))
SECRET = os.environ.get("LTZ_ATTESTOR_HMAC_SECRET", "dev-insecure-secret").encode()
REGISTRY = Path(os.environ.get("LTZ_ATTESTOR_REGISTRY", "/var/lib/ltz-attestor/devices.json"))
CHALLENGES = Path(os.environ.get("LTZ_ATTESTOR_CHALLENGES", "/var/lib/ltz-attestor/challenges.json"))
REQUIRE_ENROLL = os.environ.get("LTZ_ATTESTOR_REQUIRE_ENROLL", "1") == "1"
CHALLENGE_TTL = int(os.environ.get("LTZ_ATTESTOR_CHALLENGE_TTL", "300"))

BACKEND = load_backend()


def _load_json(path: Path) -> dict:
    if not path.exists():
        return {}
    return json.loads(path.read_text())


def _save_json(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(data, indent=2))
    tmp.replace(path)


def _load_registry() -> dict:
    return _load_json(REGISTRY)


def _save_registry(data: dict) -> None:
    _save_json(REGISTRY, data)


def _load_challenges() -> dict:
    data = _load_json(CHALLENGES)
    now = int(time.time())
    # prune expired
    dead = [k for k, v in data.items() if int(v.get("expires_at", 0)) < now]
    for k in dead:
        del data[k]
    if dead:
        _save_json(CHALLENGES, data)
    return data


def _save_challenges(data: dict) -> None:
    _save_json(CHALLENGES, data)


def _mint_ticket(device_id: str) -> tuple[str, int]:
    exp = int(time.time()) + TTL
    body = f"{device_id}:{exp}:{uuid.uuid4().hex}"
    sig = hmac.new(SECRET, body.encode(), hashlib.sha256).hexdigest()
    ticket = f"{body}:{sig}"
    return ticket, exp


def _verify_ticket(ticket: str) -> str | None:
    try:
        device_id, exp_s, _nonce, sig = ticket.rsplit(":", 3)
        exp = int(exp_s)
        if time.time() >= exp:
            return None
        body = f"{device_id}:{exp_s}:{_nonce}"
        expect = hmac.new(SECRET, body.encode(), hashlib.sha256).hexdigest()
        if not hmac.compare_digest(expect, sig):
            return None
        return device_id
    except Exception:
        return None


@app.get("/healthz")
def healthz():
    return jsonify(status="ok", backend=getattr(BACKEND, "name", "unknown")), 200


@app.get("/v1/meta")
def meta():
    """Client-safe capability advertisement (no secrets)."""
    return jsonify(
        api_version=2,
        backend=getattr(BACKEND, "name", "unknown"),
        endpoints=["/v1/enroll", "/v1/challenge", "/v1/attest", "/v1/verify_ticket"],
        evidence_schemes=["hmac_v1", "hmac_v1+tpm_quote"],
        notes="Agent talks only to this service; MAA is server-side if configured.",
    )


@app.post("/v1/enroll")
def enroll():
    data = request.get_json(force=True, silent=True) or {}
    device_id = data.get("device_id")
    join_token = data.get("join_token", "")
    expected = os.environ.get("LTZ_ATTESTOR_JOIN_TOKEN", "")
    if expected and join_token != expected:
        return jsonify(error="invalid join token"), 403
    if not device_id:
        return jsonify(error="device_id required"), 400

    # Per-device secret for evidence HMAC (returned once; agent must store).
    device_secret = secrets.token_hex(32)
    reg = _load_registry()
    reg[device_id] = {
        "enrolled_at": int(time.time()),
        "device_secret": device_secret,
        "pubkey": data.get("pubkey"),
        "ak_pub": data.get("ak_pub"),
        "meta": data.get("meta") or {},
    }
    _save_registry(reg)
    return (
        jsonify(
            device_id=device_id,
            status="enrolled",
            device_secret=device_secret,
            api_version=2,
        ),
        201,
    )


@app.post("/v1/challenge")
def challenge():
    data = request.get_json(force=True, silent=True) or {}
    device_id = data.get("device_id")
    if not device_id:
        return jsonify(error="device_id required"), 400

    reg = _load_registry()
    if REQUIRE_ENROLL and device_id not in reg:
        return jsonify(error="device not enrolled"), 403

    challenge_id = uuid.uuid4().hex
    nonce = secrets.token_hex(16)
    expires_at = int(time.time()) + CHALLENGE_TTL
    ch = {
        "challenge_id": challenge_id,
        "device_id": device_id,
        "nonce": nonce,
        "expires_at": expires_at,
        "created_at": int(time.time()),
    }
    all_ch = _load_challenges()
    all_ch[challenge_id] = ch
    _save_challenges(all_ch)
    return jsonify(
        challenge_id=challenge_id,
        nonce=nonce,
        expires_at=expires_at,
        device_id=device_id,
    )


@app.post("/v1/attest")
def attest():
    data = request.get_json(force=True, silent=True) or {}
    device_id = data.get("device_id")
    challenge_id = data.get("challenge_id")
    evidence = data.get("evidence") or {}
    if not device_id:
        return jsonify(error="device_id required"), 400
    if not challenge_id:
        return jsonify(error="challenge_id required (POST /v1/challenge first)"), 400

    reg = _load_registry()
    if REQUIRE_ENROLL and device_id not in reg:
        return jsonify(error="device not enrolled"), 403
    device_record = reg.get(device_id) or {}

    challenges = _load_challenges()
    ch = challenges.get(challenge_id)
    if not ch:
        return jsonify(error="unknown or expired challenge"), 403
    if ch.get("device_id") != device_id:
        return jsonify(error="challenge device_id mismatch"), 403
    if int(time.time()) >= int(ch.get("expires_at", 0)):
        challenges.pop(challenge_id, None)
        _save_challenges(challenges)
        return jsonify(error="challenge expired"), 403

    # Ensure evidence carries challenge binding fields for backends
    evidence = dict(evidence)
    evidence.setdefault("challenge_id", challenge_id)
    evidence.setdefault("nonce", ch["nonce"])

    try:
        result = BACKEND.verify(
            device_id=device_id,
            device_record=device_record,
            challenge=ch,
            evidence=evidence,
        )
    except VerificationError as e:
        return jsonify(error=str(e), backend=getattr(BACKEND, "name", "?")), e.code

    # Single-use challenge
    challenges.pop(challenge_id, None)
    _save_challenges(challenges)

    ticket, exp = _mint_ticket(device_id)
    return jsonify(
        ticket=ticket,
        expires_at=exp,
        device_id=device_id,
        backend=result.backend,
        verification=result.details,
    )


@app.post("/v1/verify_ticket")
def verify_ticket():
    data = request.get_json(force=True, silent=True) or {}
    device_id = _verify_ticket(data.get("ticket") or "")
    if not device_id:
        return jsonify(valid=False), 403
    return jsonify(valid=True, device_id=device_id)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", "8443")))
