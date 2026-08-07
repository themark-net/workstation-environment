#!/usr/bin/env python3
"""Thin attestor — MVP reference implementation (standalone)."""
from __future__ import annotations

import hmac
import hashlib
import json
import os
import time
import uuid
from pathlib import Path

from flask import Flask, jsonify, request

app = Flask(__name__)

TTL = int(os.environ.get("LTZ_ATTESTOR_TOKEN_TTL", "3600"))
SECRET = os.environ.get("LTZ_ATTESTOR_HMAC_SECRET", "dev-insecure-secret").encode()
REGISTRY = Path(os.environ.get("LTZ_ATTESTOR_REGISTRY", "/var/lib/ltz-attestor/devices.json"))
STRICT_TPM = os.environ.get("LTZ_ATTESTOR_STRICT_TPM", "0") == "1"
REQUIRE_ENROLL = os.environ.get("LTZ_ATTESTOR_REQUIRE_ENROLL", "1") == "1"


def _load_registry() -> dict:
    if not REGISTRY.exists():
        return {}
    return json.loads(REGISTRY.read_text())


def _save_registry(data: dict) -> None:
    REGISTRY.parent.mkdir(parents=True, exist_ok=True)
    REGISTRY.write_text(json.dumps(data, indent=2))


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
    return "ok", 200


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
    reg = _load_registry()
    reg[device_id] = {
        "enrolled_at": int(time.time()),
        "pubkey": data.get("pubkey"),
        "meta": data.get("meta") or {},
    }
    _save_registry(reg)
    return jsonify(device_id=device_id, status="enrolled"), 201


@app.post("/v1/attest")
def attest():
    data = request.get_json(force=True, silent=True) or {}
    device_id = data.get("device_id")
    evidence = data.get("evidence") or {}
    if not device_id:
        return jsonify(error="device_id required"), 400

    reg = _load_registry()
    if REQUIRE_ENROLL and device_id not in reg:
        return jsonify(error="device not enrolled"), 403

    ts = int(evidence.get("ts") or 0)
    if abs(int(time.time()) - ts) > 600:
        return jsonify(error="evidence timestamp out of window"), 403

    if STRICT_TPM and not evidence.get("tpm_present"):
        return jsonify(error="tpm required"), 403

    ticket, exp = _mint_ticket(device_id)
    return jsonify(ticket=ticket, expires_at=exp, device_id=device_id)


@app.post("/v1/verify_ticket")
def verify_ticket():
    data = request.get_json(force=True, silent=True) or {}
    device_id = _verify_ticket(data.get("ticket") or "")
    if not device_id:
        return jsonify(valid=False), 403
    return jsonify(valid=True, device_id=device_id)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", "8443")))
