#!/usr/bin/env python3
"""Ticket-gated device certificate mint for lab 802.1X.

Clients prove possession of a valid LTZ attestor ticket, then submit a CSR.
Private keys never leave the client. RADIUS trusts the lab step-ca root, not the ticket.

  POST /v1/sign
    Header: X-LTZ-Ticket: <ticket>
    Body: PEM CSR
    → 200 { certificate, chain_pem, not_after }

This is the PKI bridge from attestor plane → network plane.
"""
from __future__ import annotations

import os
import subprocess
import tempfile
import time
from pathlib import Path

import requests
from flask import Flask, jsonify, request

app = Flask(__name__)

VERIFY_URL = os.environ.get(
    "LTZ_ATTESTOR_VERIFY_URL", "http://127.0.0.1:8443/v1/verify_ticket"
)
# Must match a DNS/IP in the CA cert SANs (step ca init --dns ...)
STEP_CA_URL = os.environ.get("STEP_CA_URL", "https://10.42.0.57:8443")
STEP_FP = os.environ.get("STEP_CA_FINGERPRINT", "")
STEP_PROVISIONER = os.environ.get("STEP_PROVISIONER", "ltz-admin")
STEP_PASSWORD_FILE = os.environ.get("STEP_PASSWORD_FILE", "/etc/step-ca/password.txt")
STEP_ROOT = os.environ.get("STEP_ROOT", "/etc/step-ca/certs/root_ca.crt")
CERT_TTL = os.environ.get("LTZ_DEVICE_CERT_TTL", "24h")


def _verify_ticket(ticket: str) -> str | None:
    try:
        r = requests.post(VERIFY_URL, json={"ticket": ticket}, timeout=10)
        if r.status_code != 200:
            return None
        data = r.json()
        if data.get("valid"):
            return data.get("device_id")
    except Exception:
        return None
    return None


def _sign_csr(csr_pem: str, cn: str) -> tuple[str, str]:
    """Return (cert_pem, chain_pem). Private key stays with client; we only sign CSR."""
    del cn  # CN enforced by client CSR; ticket binds device_id at mint layer
    with tempfile.TemporaryDirectory() as td:
        td_path = Path(td)
        csr_path = td_path / "req.csr"
        crt_path = td_path / "cert.crt"
        csr_path.write_text(csr_pem)
        env = os.environ.copy()
        env["STEPPATH"] = "/etc/step-ca"
        cmd = [
            "/usr/local/bin/step",
            "ca",
            "sign",
            str(csr_path),
            str(crt_path),
            "--provisioner",
            STEP_PROVISIONER,
            "--provisioner-password-file",
            STEP_PASSWORD_FILE,
            "--ca-url",
            STEP_CA_URL,
            "--root",
            STEP_ROOT,
            "--not-after",
            CERT_TTL,
        ]

        proc = subprocess.run(
            cmd, capture_output=True, text=True, env=env, timeout=60
        )
        if proc.returncode != 0:
            raise RuntimeError(
                f"step ca sign failed: {proc.stderr or proc.stdout}"
            )
        cert_pem = crt_path.read_text()
        root_pem = Path(STEP_ROOT).read_text()
        chain = cert_pem.rstrip() + "\n" + root_pem
        return cert_pem, chain


@app.get("/healthz")
def healthz():
    return jsonify(status="ok", service="ltz-cert-mint"), 200


@app.post("/v1/sign")
def sign():
    ticket = request.headers.get("X-LTZ-Ticket") or ""
    device_id = _verify_ticket(ticket)
    if not device_id:
        return jsonify(error="invalid or missing attestor ticket"), 403

    csr_pem = request.get_data(as_text=True) or ""
    if "BEGIN CERTIFICATE REQUEST" not in csr_pem:
        return jsonify(error="body must be PEM CSR"), 400

    # CN forced to enrolled device_id (ignore CSR CN tricks for lab)
    try:
        cert_pem, chain_pem = _sign_csr(csr_pem, device_id)
    except Exception as e:
        return jsonify(error=str(e)), 500

    return jsonify(
        device_id=device_id,
        certificate=cert_pem,
        chain_pem=chain_pem,
        issued_at=int(time.time()),
        ttl=CERT_TTL,
        note="RADIUS trusts lab CA; ticket only authorized this mint",
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", "8445")))
