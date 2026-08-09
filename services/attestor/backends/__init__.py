"""Evidence verification backends for the thin attestor.

The HTTP API and tickets stay stable. Only the verifier behind /v1/attest changes:

  LTZ_ATTESTOR_BACKEND=local   # default — challenge + HMAC (+ optional TPM quote)
  LTZ_ATTESTOR_BACKEND=maa     # Microsoft Azure Attestation (requires Azure; see maa.py)
"""
from __future__ import annotations

import os

from .base import EvidenceBackend, VerificationError, VerificationResult
from .local import LocalBackend
from .maa import MaaBackend


def load_backend() -> EvidenceBackend:
    name = os.environ.get("LTZ_ATTESTOR_BACKEND", "local").strip().lower()
    if name in ("local", "lab", "hmac"):
        return LocalBackend()
    if name in ("maa", "azure", "azure_attestation"):
        return MaaBackend()
    raise RuntimeError(f"unknown LTZ_ATTESTOR_BACKEND={name!r} (use local|maa)")


__all__ = [
    "EvidenceBackend",
    "VerificationError",
    "VerificationResult",
    "load_backend",
    "LocalBackend",
    "MaaBackend",
]
