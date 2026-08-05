# Executive Proposal: Linux Zero Trust Workstations & Workload Identity

**Program:** Linux Zero Trust Workstation & Workload Identity (LZT-WWI)  
**Date:** 2026-08-05  
**Audience:** Security architecture, IAM, platform leadership, PMO  
**Classification:** Internal

---

## 1. Problem

Windows endpoints are accepted as corporate-managed because they sit on a familiar path: **Entra identity**, **Intune compliance**, and **Conditional Access**. Linux workstations already authenticate users (SSSD OIDC + hybrid UID/GID) and can be baselined (goldimage Ansible), but they are still treated as second-class because:

1. There is no **Hello-class, device-bound, no-dongle** phishing-resistant path into Entra for daily UX.
2. **Device health** is not a first-class Conditional Access signal comparable to Windows compliance.
3. **Semi-privileged local services** rely on a sprawl of local accounts and static secrets rather than enterprise-issued workload identity.
4. Configuration is strong at image time but not yet **continuously enforced and fail-closed** the way architects expect from Entra-joined estates.

Without a funded program, Linux either remains blocked from sensitive apps or is granted exceptions that weaken Zero Trust.

---

## 2. Recommendation

Fund a single program that extends the **existing Microsoft control plane** to Linux—not a parallel Linux security stack.

| Control | Approach |
|---------|----------|
| Human passwordless Entra | **TPM-backed certificate-based authentication (CBA)** — **no USB** for day-to-day |
| Device trust | **Intune enrollment + compliance** (built-in + custom trust agent) |
| Access | **Same Conditional Access** policies (report-only → enforce) |
| OS configuration depth | **New AWX (OSS)** continuous Ansible; consume **goldimage** baselines |
| Non-human / agent identity | **MS CA Workload Intermediate** certs; **SPIRE** for platform/attested workloads |
| Local login | Keep **SSSD OIDC hybrid** (already delivered) |

SPIFFE/SPIRE is explicitly **workload identity**, not a replacement for Entra user/device trust.

---

## 3. Outcomes (what “done” means)

1. Pilot Linux users access protected apps with **phishing-resistant CBA** and **compliant device** claims.
2. Non-compliant or drifted hosts **lose access** (fail-closed), matching Windows Entra philosophy.
3. In-scope client agents use **enterprise workload certificates** (no static shared secrets).
4. Platform teams run **SPIRE** for service mTLS / future Entra workload federation.
5. Delivery is tracked in **Jira** with **GitLab** issues linked to the same backlog.

---

## 4. Scope

### In scope

- Architecture & runbooks (this repository)
- New AWX instance + integration with goldimage playbooks
- Trust agent + Intune custom compliance
- MS CA workload intermediate lifecycle via Ansible
- SPIRE platform deployment
- TPM-CBA enrollment path for pilot users
- Entra/Intune/PKI access requests (limited admin rights assumed)
- Jira + GitLab import packs for agile delivery

### Out of scope

- Microsoft Autopilot for Linux (not a product path)
- Replacing SSSD OIDC hybrid (already done)
- Rewriting goldimage (consume, do not fork)
- Full SPIRE on every laptop day one
- Tenant-wide password disable

---

## 5. Investment summary

| Category | Effort (person-hours) | Notes |
|----------|----------------------:|-------|
| Platform AWX | 120 | Deploy, CasC, inventories, job templates |
| Goldimage integration + baseline layering | 40 | Consume tags; thin glue |
| Trust agent + Intune compliance bridge | 100 | Agent, policies, pilot |
| Workload PKI + cert automation | 120 | Depends on PKI lead time |
| SPIRE infrastructure | 140 | HA server, agents, policies, pilot mTLS |
| User TPM-CBA | 160 | Enrollment UX, broker, pilot, docs |
| Entra/IAM request packaging & coordination | 40 | Formal access requests |
| Security testing & architect review | 60 | |
| Project Mgmt / backlog hygiene | 48 | Jira/GitLab |
| Contingency (15%) | ~124 | Entra/PKI lag, TPM edge cases |
| **Total** | **~952 hours** | ≈ **0.5 FTE-year** or **~6 FTE-months** blended |

See [COST-ESTIMATES.md](COST-ESTIMATES.md) for story-level breakdown suitable for Jira.

**Calendar duration (recommended):** 4–6 months elapsed with parallel workstreams and external IAM/PKI dependencies.

**Cash cost (software):** AWX OSS + SPIRE OSS + existing Microsoft licenses (Entra ID P1/P2, Intune as already entitled). No new identity product license assumed. Hardware: TPM-capable fleet (already standard on modern laptops).

---

## 6. Risks & mitigations

| Risk | Mitigation |
|------|------------|
| Slow Entra/PKI approvals | Submit full request catalog week 1; parallelize AWX/SPIRE/goldimage |
| TPM-CBA client friction | Early spike; YubiKey break-glass only |
| Scope: SPIRE everywhere | Phase gate; MS CA certs default for agents |
| Perception of “parallel stack” | Executive message: same Entra/Intune/CA plane |

---

## 7. Ask

1. Approve program budget of **~950 person-hours** (plus PKI/IAM time outside Linux team).
2. Assign IAM/Intune/PKI **request owners** for REQ catalog in `docs/implementation/entra-access-requests.md`.
3. Authorize **new AWX** and **SPIRE** platform projects in GitLab.
4. Accept pilot → report-only CA → enforce gates.
5. Import agile backlog from `docs/project/` into Jira + GitLab.

---

## 8. References (internal)

- [Identity planes overview](../architecture/identity-planes-overview.md)
- [Implementation plan](../implementation/IMPLEMENTATION-PLAN.md)
- [TPM CBA no-USB](../runbooks/tpm-cba-no-usb.md)
- [AWX GPO parity](../runbooks/ansible-awx-gpo-parity.md)
- [SPIFFE/SPIRE](../architecture/spiffe-spire.md)
- [Workload certs](../architecture/workload-certs-ms-ca.md)
