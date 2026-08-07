# Workstation Environment — Documentation

**Canonical posture (2026-08-07):** **Compliance-first MVP**; Entra **CBA** is Future (Hello-class user auth), not device attestation.

## Architecture (start here)

| Document | Purpose |
|----------|---------|
| [MVP vs Future State](architecture/MVP-AND-FUTURE-STATE.md) | Phased outcomes |
| [Identity planes](architecture/identity-planes-overview.md) | Planes H/D/W/M |
| [Repo boundaries](architecture/REPO-BOUNDARIES.md) | client vs lab vs services |
| [Thin attestor](architecture/thin-attestor.md) | MVP device trust core |

## Runbooks

| Document | Purpose |
|----------|---------|
| [Linux Zero Trust with Entra](runbooks/linux-zero-trust-entra.md) | Master runbook (MVP) |
| [Intune compliance bridge](runbooks/intune-compliance-bridge.md) | Discovery/rules + attestor |
| [TPM-backed Entra CBA](runbooks/tpm-cba-no-usb.md) | **Future** user passwordless |
| [AWX GPO parity](runbooks/ansible-awx-gpo-parity.md) | Management depth |
| [Workload MS CA](runbooks/workload-certs-ms-ca.md) | Future workload |
| [SPIFFE/SPIRE](runbooks/spiffe-spire.md) | Future workload fabric |

## Implementation

| Document | Purpose |
|----------|---------|
| [Entra requests (MVP / Future)](implementation/ENTRA_REQUESTS.md) | REQ-M* / REQ-F* |
| [Dependencies & repos](implementation/dependencies-and-repos.md) | Repo map |

## Code trees

| Path | Extract as | Prod? |
|------|------------|-------|
| `client/` | `ltz-client` | **Yes** |
| `services/attestor/` | `ltz-attestor` | **Yes** |
| `services/collector/` | `ltz-collector` | **Yes** |
| `lab/` | `ltz-lab` | **No** |
