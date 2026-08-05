# Architecture: Identity & Trust Planes (Unified View)

**Status:** Approved design direction  
**Last updated:** 2026-08-05  
**Assumptions:**
- User-facing **SSSD OIDC** is **done** (custom hybrid SSSD: UID/GID with AD hybrid accounts).
- **Goldimage** Ansible playbooks exist for SSH + YubiKey Linux **admin** accounts.
- **Limited Entra/Intune access** for implementers; changes require formal Microsoft-termed access requests (see [entra-access-requests.md](../implementation/entra-access-requests.md)).
- New **AWX (OSS Tower)** instance and **SPIRE** infrastructure are in scope.
- Non-user workloads use **MS CA workload intermediate** certs; humans use **TPM-backed Entra CBA** (no USB).

---

## Planes

```text
PLANE H — HUMAN (user) ……………………… DONE / extend
  SSSD OIDC (hybrid UID/GID) · optional local session
  Entra CBA via platform TPM PKCS#11 (no USB) — TO BUILD
  YubiKey: break-glass / admin path (goldimage) — EXISTS

PLANE D — DEVICE (laptop/workstation)
  Golden image · LUKS · Intune enroll · custom compliance
  Trust agent → status.json → Intune → Conditional Access

PLANE W — WORKLOAD (non-human on clients & platform)
  MS CA Workload Intermediate → service/host client certs
  Optional SPIRE SVIDs for high-churn / attested services
  Unprivileged systemd units (not secret-bearing root accounts)

PLANE M — MANAGEMENT
  Goldimage repo: SSH, YubiKey admin, common baseline
  New AWX: continuous policy (GPO parity) + cert lifecycle
  SPIRE server(s) + agents where workload plane needs them
  GitLab: IaC / playbooks / SPIRE config
  Jira: delivery tracking (import packs in docs/project/)
```

---

## Repo map

| Repo (logical name) | Role |
|---------------------|------|
| **goldimage** | Baseline SSH, YubiKey admin, common host harden — already gold |
| **sssd-hybrid** (custom) | Hybrid identity UID/GID + OIDC — **done** |
| **workstation-environment** (this) | Architecture, runbooks, project import packs |
| **ansible-workstation-environment** | Expanded policy packs / roles for ZT fleet |
| **awx-config** (new or folder) | AWX job templates, inventories, credentials as code |
| **spire-infra** (new) | SPIRE server/agent manifests, registration policies |
| **trust-agent** (new or role) | status.json agent + systemd timer |

---

## Trust decisions (non-negotiable)

1. **No USB** for day-to-day Entra passwordless (TPM CBA).
2. **No parallel IdP** for corporate user access.
3. **Separate CA intermediates:** User/CBA vs Workload.
4. **Unix accounts ≠ network identity** — keep minimal systemd users; certs/SVIDs for off-box trust.
5. **Stale management = non-compliant** (AWX policy_gen + agent freshness → Intune).
6. SPIRE is **workload plane**, not a substitute for Entra CBA/Intune on desktops.

---

## Related docs

- [SPIFFE/SPIRE](spiffe-spire.md)
- [Workload certs MS CA](workload-certs-ms-ca.md)
- [Implementation plan](../implementation/IMPLEMENTATION-PLAN.md)
- [Executive proposal](../executive/EXECUTIVE-PROPOSAL.md)
