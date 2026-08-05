# Workstation Environment — Documentation

Operational and architectural docs for managed Linux workstations on the **same Entra / Intune / Conditional Access control plane** as Windows, plus workload identity and delivery imports.

## Runbooks

| Document | Purpose |
|----------|---------|
| [Linux Zero Trust with Entra (master)](runbooks/linux-zero-trust-entra.md) | Unified trust model, funding narrative |
| [TPM-backed Entra CBA (no USB)](runbooks/tpm-cba-no-usb.md) | Platform TPM via PKCS#11 + Entra CBA |
| [AWX policy plane & GPO parity](runbooks/ansible-awx-gpo-parity.md) | Continuous Ansible + Intune compliance |
| [Intune Linux compliance bridge](runbooks/intune-compliance-bridge.md) | status.json → custom compliance → CA |
| [Workload certs (MS CA intermediate)](runbooks/workload-certs-ms-ca.md) | Non-user service certs; systemd vs crypto identity |
| [SPIFFE / SPIRE](runbooks/spiffe-spire.md) | Workload fabric; phases; not a CBA substitute |

## Implementation & delivery

| Document | Purpose |
|----------|---------|
| [implementation/README.md](implementation/README.md) | Index |
| [Executive proposal](implementation/EXECUTIVE_PROPOSAL.md) | Steering committee |
| [Cost estimates (man-hours)](implementation/COST_ESTIMATES.md) | ~1,495 h planning total |
| [Implementation plan](implementation/IMPLEMENTATION_PLAN.md) | Phases 0–3, AWX, goldimage, SPIRE |
| [Entra request catalog](implementation/ENTRA_REQUESTS.md) | Microsoft-termed IAM tickets |

## Agile imports (Jira + GitLab)

See [imports/README.md](../imports/README.md):

- Jira CSV (epics, stories, sub-tasks)
- GitLab issues CSV
- Traceability map

## Design principles

1. **One decision plane** — Entra + Intune + Conditional Access for people/devices.  
2. **No USB** for day-to-day Entra passwordless — platform TPM + CBA.  
3. **SSSD OIDC + hybrid UID/GID** — already done; do not regress.  
4. **goldimage** — SSH + YubiKey admin baselines remain first-class.  
5. **New AWX** — continuous ZT policy packs (GPO-class).  
6. **Workload MS CA intermediate** — agents/services; not user CBA templates.  
7. **SPIRE** — Phase 2+ workload identity; optional Entra workload federation.  
8. **Limited Entra access** — all tenant changes via formal REQ-E* tickets.

## Related repos (logical)

| Alias | Role |
|-------|------|
| goldimage | Admin SSH / YubiKey baseline playbooks |
| sssd-hybrid | Custom SSSD OIDC + hybrid AD UID/GID |
| workstation-environment | This repo — architecture & imports |
| zt-awx-config | New — AWX ZT playbooks |
| zt-spire-config | New — SPIRE configuration |
