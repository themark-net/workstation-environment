from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Protocol


class VerificationError(Exception):
    """Evidence rejected by the backend."""

    def __init__(self, message: str, code: int = 403):
        super().__init__(message)
        self.code = code


@dataclass
class VerificationResult:
    ok: bool
    backend: str
    details: dict[str, Any] = field(default_factory=dict)


class EvidenceBackend(Protocol):
    name: str

    def verify(
        self,
        *,
        device_id: str,
        device_record: dict[str, Any],
        challenge: dict[str, Any],
        evidence: dict[str, Any],
    ) -> VerificationResult:
        """Validate evidence for a pending challenge. Raise VerificationError on failure."""
        ...
