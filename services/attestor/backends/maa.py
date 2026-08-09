"""Microsoft Azure Attestation backend (pluggable).

Client/agent never talk to MAA directly — only this attestor does.

Requirements (not provided by M365 E3 alone):
  - Azure subscription
  - Attestation provider endpoint
  - App registration / managed identity with rights to call MAA

Env:
  LTZ_ATTESTOR_BACKEND=maa
  LTZ_MAA_ENDPOINT=https://<provider>.<region>.attest.azure.net
  LTZ_MAA_API_VERSION=2022-08-01  (example)
  LTZ_MAA_BEARER_TOKEN=...        (lab: static; prod: MSI/AAD client credentials)

This stub validates configuration and documents the plug-in point. When credentials
are missing it fails closed with a clear error. Implement `_call_maa` when Azure is ready.
"""
from __future__ import annotations

import os
from typing import Any

from .base import VerificationError, VerificationResult
from .local import LocalBackend


class MaaBackend:
    """Prefer MAA for evidence; fall back policy is explicit fail (no silent local)."""

    name = "maa"

    def __init__(self) -> None:
        self.endpoint = os.environ.get("LTZ_MAA_ENDPOINT", "").rstrip("/")
        self.api_version = os.environ.get("LTZ_MAA_API_VERSION", "2022-08-01")
        self.token = os.environ.get("LTZ_MAA_BEARER_TOKEN", "")
        # Optional: run local HMAC first then attach MAA token for hybrid labs
        self.also_local = os.environ.get("LTZ_MAA_ALSO_LOCAL", "0") == "1"
        self._local = LocalBackend() if self.also_local else None

    def verify(
        self,
        *,
        device_id: str,
        device_record: dict[str, Any],
        challenge: dict[str, Any],
        evidence: dict[str, Any],
    ) -> VerificationResult:
        if self._local is not None:
            # Hybrid: local proof still required, then MAA (when implemented)
            local_res = self._local.verify(
                device_id=device_id,
                device_record=device_record,
                challenge=challenge,
                evidence=evidence,
            )
        else:
            local_res = None

        if not self.endpoint:
            raise VerificationError(
                "MAA backend selected but LTZ_MAA_ENDPOINT is unset "
                "(need Azure attestation provider; not included in M365 E3)",
                503,
            )
        if not self.token:
            raise VerificationError(
                "MAA backend selected but LTZ_MAA_BEARER_TOKEN is unset",
                503,
            )

        # Plug-in point: submit TEE/TPM evidence package to MAA and validate JWT.
        maa_token = evidence.get("maa_token") or evidence.get("azure_attestation_token")
        if not maa_token:
            # Future: attestor builds MAA request from evidence["tpm_quote"] etc.
            raise VerificationError(
                "MAA backend not fully wired: provide evidence.maa_token or implement "
                "backends/maa.py _attest_with_provider() for TPM/TEE payloads",
                501,
            )

        # Placeholder JWT presence check — replace with JWKS validation against MAA.
        if not isinstance(maa_token, str) or maa_token.count(".") < 2:
            raise VerificationError("invalid maa_token format", 403)

        details = {
            "maa_endpoint": self.endpoint,
            "maa_jwt_present": True,
            "local": local_res.details if local_res else None,
        }
        return VerificationResult(ok=True, backend=self.name, details=details)
