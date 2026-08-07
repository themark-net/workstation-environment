#!/usr/bin/env python3
"""Collector + mock Intune compliance sink (standalone)."""
from __future__ import annotations

import os
import time
from typing import Any

import requests
from flask import Flask, jsonify, request

app = Flask(__name__)

VERIFY_URL = os.environ.get("LTZ_ATTESTOR_VERIFY_URL", "http://127.0.0.1:8443/v1/verify_ticket")
REPORTS: dict[str, Any] = {}
MOCK_COMPLIANT: dict[str, bool] = {}


def _ticket_valid(ticket: str) -> str | None:
    try:
        r = requests.post(VERIFY_URL, json={"ticket": ticket}, timeout=5)
        if r.status_code != 200:
            return None
        data = r.json()
        if data.get("valid"):
            return data.get("device_id")
    except Exception:
        return None
    return None


@app.get("/healthz")
def healthz():
    return "ok", 200


@app.post("/v1/report")
def report():
    ticket = request.headers.get("X-LTZ-Ticket") or ""
    device_id = _ticket_valid(ticket)
    if not device_id:
        return jsonify(error="invalid or missing ticket"), 403
    body = request.get_json(force=True, silent=True) or {}
    REPORTS[device_id] = {"ts": int(time.time()), "body": body}
    MOCK_COMPLIANT[device_id] = bool(body.get("attested"))
    return jsonify(accepted=True, device_id=device_id, mock_compliant=MOCK_COMPLIANT[device_id])


@app.get("/v1/mock-intune/<device_id>")
def mock_intune(device_id: str):
    return jsonify(
        device_id=device_id,
        compliant=MOCK_COMPLIANT.get(device_id, False),
        last_report=REPORTS.get(device_id),
    )


@app.get("/v1/mock-intune")
def mock_intune_all():
    return jsonify(MOCK_COMPLIANT)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", "8089")))
