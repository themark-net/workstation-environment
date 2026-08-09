# Workstation Environment — Documentation

**Canonical posture (2026-08-07):** **Compliance-first MVP**; Entra **CBA** is Future (Hello-class user auth), not device attestation.

## Architecture (start here)

| Document | Purpose |
|----------|---------|
| [MVP vs Future State](architecture/MVP-AND-FUTURE-STATE.md) | Phased outcomes |
| [Identity planes](architecture/identity-planes-overview.md) | Planes H/D/W/M |
| [Repo boundaries](architecture/REPO-BOUNDARIES.md) | client vs lab vs services |
| [Thin attestor](architecture/thin-attestor.md) | MVP device trust core |
| [Device 802.1X EAP-TLS](architecture/device-8021x-eap-tls.md) | Machine network auth on device cert |

## Presentations

| Document | Purpose |
|----------|---------|
| [presentations/](presentations/) | High-level executive briefing |
| [ltz-deck.js](presentations/ltz-deck.js) | PptxGenJS source — run with `node` to build `.pptx` |

## Runbooks

| Document | Purpose |
|----------|---------|
| [Linux Zero Trust with Entra](runbooks/linux-zero-trust-entra.md) | Master runbook (MVP) |
| [Intune compliance bridge](runbooks/intune-compliance-bridge.md) | Discovery/rules + attestor |
| [Device 802.1X EAP-TLS](runbooks/device-8021x-eap-tls.md) | Machine EAP-TLS runbook |
| [TPM-backed Entra CBA](runbooks/tpm-cba-no-usb.md) | **Future** user passwordless |
| [AWX GPO parity](runbooks/ansible-awx-gpo-parity.md) | Management depth |
| [Workload MS CA](runbooks/workload-certs-ms-ca.md) | Future workload |
| [SPIFFE/SPIRE](runbooks/spiffe-spire.md) | Future workload fabric |

## Deployment (lab → Microsoft)

| Document | Purpose |
|----------|---------|
| [deployment/README.md](deployment/README.md) | Transition model: one Ansible, one vars surface |
| [Lab trust proof](deployment/lab-trust-proof.md) | Air-gap evidence + plane mapping |
| [Microsoft path](deployment/microsoft-path.md) | Same bootstrap on real/dev hosts |
| [Entra / Azure checklist](deployment/entra-azure-checklist.md) | Portal work for MVP device path |

## Implementation

| Document | Purpose |
|----------|---------|
| [Entra requests (MVP / Future)](implementation/ENTRA_REQUESTS.md) | REQ-M* / REQ-F* |
| [Dependencies & repos](implementation/dependencies-and-repos.md) | Repo map |
| [Executive proposal](executive/EXECUTIVE-PROPOSAL.md) | Steering |

## Code trees

| Path | Extract as | Prod? |
|------|------------|-------|
| `client/` | `ltz-client` | **Yes** |
| `services/attestor/` | `ltz-attestor` | **Yes** |
| `services/collector/` | `ltz-collector` | **Yes** |
| `lab/` | `ltz-lab` | **No** |
