#!/usr/bin/env python3
"""Thin attestor — MVP reference implementation (standalone).

Mints short-lived tickets and, when enabled, device client certificates
for machine 802.1X EAP-TLS (same posture gate).
"""
from __future__ import annotations

import hmac
import hashlib
import json
import os
import subprocess
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
ISSUE_DEVICE_CERT = os.environ.get("LTZ_ATTESTOR_ISSUE_DEVICE_CERT", "0") == "1"
DEVICE_CA_DIR = Path(os.environ.get("LTZ_ATTESTOR_DEVICE_CA_DIR", "/var/lib/ltz-attestor/device-ca"))
CERT_TTL = int(os.environ.get("LTZ_ATTESTOR_CERT_TTL", str(TTL)))


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


def _ensure_device_ca() -> None:
    """Create a lab/dev device CA with openssl if missing."""
    ca_key = DEVICE_CA_DIR / "ca.key"
    ca_crt = DEVICE_CA_DIR / "ca.crt"
    if ca_key.exists() and ca_crt.exists():
        return
    DEVICE_CA_DIR.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        [
            "openssl",
            "req",
            "-x509",
            "-newkey",
            "rsa:2048",
            "-nodes",
            "-keyout",
            str(ca_key),
            "-out",
            str(ca_crt),
            "-days",
            "3650",
            "-subj",
            "/CN=LTZ Device CA/O=LTZ/OU=Device",
        ],
        check=True,
        capture_output=True,
    )
    ca_key.chmod(0o600)
    ca_crt.chmod(0o644)


def _issue_device_cert(device_id: str) -> dict:
    """Issue a short-lived device client cert. Returns PEM strings + expiry."""
    _ensure_device_ca()
    work = DEVICE_CA_DIR / "issued" / device_id.replace("/", "_")
    work.mkdir(parents=True, exist_ok=True)
    key_path = work / "device.key"
    csr_path = work / "device.csr"
    crt_path = work / "device.crt"
    ext_path = work / "ext.cnf"

    # Key + CSR
    subprocess.run(
        [
            "openssl",
            "req",
            "-new",
            "-newkey",
            "rsa:2048",
            "-nodes",
            "-keyout",
            str(key_path),
            "-out",
            str(csr_path),
            "-subj",
            f"/CN={device_id}/O=LTZ/OU=Device",
        ],
        check=True,
        capture_output=True,
    )
    key_path.chmod(0o600)

    # Client Auth EKU
    ext_path.write_text(
        "basicConstraints=CA:FALSE\n"
        "keyUsage=digitalSignature,keyEncipherment\n"
        "extendedKeyUsage=clientAuth\n"
        f"subjectAltName=DNS:{device_id},URI:spiffe://ltz.lab/device/{device_id}\n"
    )

    # days must be at least 1 for openssl -days; use seconds via -not_after when possible
    days = max(1, (CERT_TTL + 86399) // 86400)
    # Prefer short validity: use -days 1 for TTL < 1d, else ceil days
    if CERT_TTL < 86400:
        days = 1

    subprocess.run(
        [
            "openssl",
            "x509",
            "-req",
            "-in",
            str(csr_path),
            "-CA",
            str(DEVICE_CA_DIR / "ca.crt"),
            "-CAkey",
            str(DEVICE_CA_DIR / "ca.key"),
            "-CAcreateserial",
            "-out",
            str(crt_path),
            "-days",
            str(days),
            "-extfile",
            str(ext_path),
        ],
        check=True,
        capture_output=True,
    )
    crt_path.chmod(0o644)

    # Compute notAfter as unix if possible
    exp = int(time.time()) + min(CERT_TTL, days * 86400)
    try:
        out = subprocess.check_output(
            ["openssl", "x509", "-in", str(crt_path), "-noout", "-enddate"],
            text=True,
        )
        # notAfter=Aug  8 22:00:00 2026 GMT
        from datetime import datetime, timezone

        raw = out.strip().split("=", 1)[1]
        dt = datetime.strptime(raw, "%b %d %H:%M:%S %Y %Z").replace(tzinfo=timezone.utc)
        exp = int(dt.timestamp())
    except Exception:
        pass

    return {
        "certificate_pem": crt_path.read_text(),
        "private_key_pem": key_path.read_text(),
        "ca_pem": (DEVICE_CA_DIR / "ca.crt").read_text(),
        "expires_at": exp,
        "device_id": device_id,
    }


@app.get("/healthz")
def healthz():
    return "ok", 200


@app.get("/v1/device_ca")
def device_ca():
    """Publish device CA cert for RADIUS / clients (when cert issuance enabled)."""
    if not ISSUE_DEVICE_CERT:
        return jsonify(error="device cert issuance disabled"), 404
    _ensure_device_ca()
    ca = (DEVICE_CA_DIR / "ca.crt").read_text()
    return jsonify(ca_pem=ca), 200


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
    body: dict = {"ticket": ticket, "expires_at": exp, "device_id": device_id}

    if ISSUE_DEVICE_CERT:
        try:
            cert = _issue_device_cert(device_id)
            body["device_cert"] = {
                "certificate_pem": cert["certificate_pem"],
                "private_key_pem": cert["private_key_pem"],
                "ca_pem": cert["ca_pem"],
                "expires_at": cert["expires_at"],
            }
        except subprocess.CalledProcessError as e:
            return jsonify(error="device cert mint failed", detail=e.stderr.decode() if e.stderr else str(e)), 500

    return jsonify(body)


@app.post("/v1/verify_ticket")
def verify_ticket():
    data = request.get_json(force=True, silent=True) or {}
    device_id = _verify_ticket(data.get("ticket") or "")
    if not device_id:
        return jsonify(valid=False), 403
    return jsonify(valid=True, device_id=device_id)


if __name__ == "__main__":
    if ISSUE_DEVICE_CERT:
        _ensure_device_ca()
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", "8443")))
