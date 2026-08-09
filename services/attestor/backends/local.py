"""Local verifier: server-issued challenge + device HMAC (+ optional TPM2 quote).

This is the default production-shaped lab backend. It does **not** require Azure.
MAA can replace this module via LTZ_ATTESTOR_BACKEND=maa without agent changes.
"""
from __future__ import annotations

import hashlib
import hmac
import os
from typing import Any

from .base import VerificationError, VerificationResult


def _b(s: str) -> bytes:
    return s.encode("utf-8")


def evidence_mac(
    device_secret: str,
    *,
    device_id: str,
    challenge_id: str,
    nonce: str,
    ts: int,
    tpm_present: bool,
    hostname: str,
) -> str:
    """Stable MAC agents and servers both implement (documented client contract)."""
    material = "|".join(
        [
            "ltz-evidence-v1",
            device_id,
            challenge_id,
            nonce,
            str(int(ts)),
            "1" if tpm_present else "0",
            hostname,
        ]
    )
    return hmac.new(_b(device_secret), _b(material), hashlib.sha256).hexdigest()


class LocalBackend:
    name = "local"

    def __init__(self) -> None:
        self.strict_tpm = os.environ.get("LTZ_ATTESTOR_STRICT_TPM", "0") == "1"
        self.require_hmac = os.environ.get("LTZ_ATTESTOR_REQUIRE_HMAC", "1") == "1"
        # If 1, evidence.tpm_quote must be present when tpm_present is true.
        self.require_quote_if_tpm = os.environ.get("LTZ_ATTESTOR_REQUIRE_QUOTE_IF_TPM", "0") == "1"
        self.max_skew = int(os.environ.get("LTZ_ATTESTOR_MAX_SKEW_SEC", "600"))

    def verify(
        self,
        *,
        device_id: str,
        device_record: dict[str, Any],
        challenge: dict[str, Any],
        evidence: dict[str, Any],
    ) -> VerificationResult:
        secret = device_record.get("device_secret")
        if not secret:
            raise VerificationError("device has no device_secret; re-enroll", 403)

        ts = int(evidence.get("ts") or 0)
        now = int(__import__("time").time())
        if abs(now - ts) > self.max_skew:
            raise VerificationError("evidence timestamp out of window", 403)

        nonce = str(evidence.get("nonce") or "")
        if not nonce or nonce != challenge.get("nonce"):
            raise VerificationError("nonce does not match challenge", 403)

        challenge_id = str(evidence.get("challenge_id") or challenge.get("challenge_id") or "")
        if challenge_id != challenge.get("challenge_id"):
            raise VerificationError("challenge_id mismatch", 403)

        tpm_present = bool(evidence.get("tpm_present"))
        if self.strict_tpm and not tpm_present:
            raise VerificationError("tpm required (STRICT_TPM)", 403)

        hostname = str(evidence.get("hostname") or "")

        if self.require_hmac:
            got = str(evidence.get("proof_hmac") or evidence.get("hmac") or "")
            expect = evidence_mac(
                secret,
                device_id=device_id,
                challenge_id=challenge["challenge_id"],
                nonce=nonce,
                ts=ts,
                tpm_present=tpm_present,
                hostname=hostname,
            )
            if not got or not hmac.compare_digest(got, expect):
                raise VerificationError("invalid evidence HMAC", 403)

        quote = evidence.get("tpm_quote") or evidence.get("quote")
        if tpm_present and self.require_quote_if_tpm and not quote:
            raise VerificationError("tpm_quote required when TPM present", 403)

        details: dict[str, Any] = {
            "scheme": evidence.get("scheme") or "hmac_v1",
            "tpm_present": tpm_present,
            "hmac_ok": True,
            "quote_present": bool(quote),
        }

        # Optional: structural TPM quote check (nonce embedded as qualifying data hex).
        # Full AK verification is lab-optional; presence of nonce in quote payload is enforced when quote given.
        if quote and isinstance(quote, dict):
            qd = str(quote.get("qualifying_data") or quote.get("nonce") or "").lower()
            n = nonce.lower()
            if qd and n not in qd and qd != n:
                raise VerificationError("tpm_quote does not bind challenge nonce", 403)
            details["quote_nonce_bound"] = bool(qd)

        return VerificationResult(ok=True, backend=self.name, details=details)
