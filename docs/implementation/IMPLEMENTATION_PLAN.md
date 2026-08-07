# Implementation Plan — Linux Zero Trust (Compliance-First)

**Version:** 2.0  
**Date:** 2026-08-07  
**Canonical phasing:** [../architecture/MVP-AND-FUTURE-STATE.md](../architecture/MVP-AND-FUTURE-STATE.md)

---

## 0. Constraints

| Item | Assumption |
|------|------------|
| SSSD OIDC + hybrid UID/GID | **Done** |
| Goldimage (SSH + YubiKey admin) | **Exists** |
| Entra / Intune rights | **Limited** — [ENTRA_REQUESTS.md](ENTRA_REQUESTS.md) / [entra-access-requests.md](entra-access-requests.md) |
| Autopilot for Linux | **Out of scope** |
| Entra CBA (Hello-class user) | **Future** — not MVP blocker |
| SPIRE / workload MS CA | **Future** after MVP device trust |

---

## 1. Objectives

### MVP (fund and deliver first)

1. Linux **device trust** accepted under Conditional Access via **compliant device**.  
2. **Thin attestor** + compliance agent so posture is not “local script honesty only.”  
3. Prewritten Intune discovery/rules; plug in when tenant allows.  
4. Production client code (**ltz-client**) has **zero** dependency on lab.  
5. Lab proves enroll → attest → ticket → report → fail-closed.

### Future (after MVP)

6. Entra **CBA** / FIDO for phishing-resistant **user** auth (no USB day-to-day).  
7. AWX continuous policy (GPO-class).  
8. Workload MS CA intermediate ± SPIRE.

---

## 2. Phase overview

| Phase | Name | Outcome | Calendar (rough) |
|-------|------|---------|------------------|
| **M0** | Foundations | Repos extracted/pinned; lab MVP runnable; RACI | 1–2 weeks |
| **M1** | Device trust MVP | Attestor, agent, collector; Intune artifacts; mock→real compliance | 4–6 weeks |
| **M2** | Tenant plug-in | REQ-M* granted; enroll pilot; CA compliant device report-only→on | Depends on IAM |
| **F1** | User CBA / FIDO | REQ-F*; TPM PKCS#11 path; auth strength (optional) | After M2 |
| **F2** | Management depth | New AWX + goldimage assert + policy packs | Parallel/after M1 |
| **F3** | Workload identity | MS CA intermediate ± SPIRE | After M2 |

---

## 3. Phase M0 — Foundations

- Confirm **REPO-BOUNDARIES**: `client/`, `services/*` extractable; `lab/` never in prod AWX.  
- Lab: `make ansible-mvp` green on Proxmox (or docker smoke).  
- Pin tags; document owners.

**Exit:** Demo script produces happy-path + fail-closed evidence without Entra.

---

## 4. Phase M1 — Device trust MVP (no CBA)

| Workstream | Deliverable |
|------------|-------------|
| Thin attestor | `services/attestor` — enroll + attest + short-lived ticket |
| Collector | `services/collector` — ticket-gated reports; mock Intune |
| Client agent | `client/` agent + systemd; Ansible role |
| Intune artifacts | `client/intune/discovery.sh` + `rules.json` |
| Lab orchestration | `lab/ansible/playbooks/mvp.yml` |

**Exit:** Attested device gets ticket; unenrolled/expired denied; discovery JSON reflects ticket freshness.

---

## 5. Phase M2 — Tenant plug-in (REQ-M*)

File and complete **REQ-M01–M10** (see ENTRA_REQUESTS.md):

1. Intune Linux enroll + licenses  
2. Built-in + custom compliance (upload artifacts)  
3. CA **require compliant device** (report-only → on)  
4. Break-glass exclusions  

**Exit:** Pilot Linux hosts show **Compliant**; pilot app CA grants/denies on that bit.

---

## 6. Future phases (summary)

| Phase | Work | REQs |
|-------|------|------|
| **F1** | TPM CBA or FIDO; no USB daily UX | REQ-F01–F08 |
| **F2** | AWX ZT packs, continuous enforce | — |
| **F3** | Workload certs, optional SPIRE, federation | REQ-F10 |

Details: [tpm-cba-no-usb.md](../runbooks/tpm-cba-no-usb.md), [workload-certs-ms-ca.md](../runbooks/workload-certs-ms-ca.md), [spiffe-spire.md](../runbooks/spiffe-spire.md).

---

## 7. Repo map

See [dependencies-and-repos.md](dependencies-and-repos.md) and [../architecture/REPO-BOUNDARIES.md](../architecture/REPO-BOUNDARIES.md).

---

## 8. Risks

| Risk | Mitigation |
|------|------------|
| IAM delay on REQ-M* | Lab + mock Intune continues; no idle engineering |
| Custom compliance forgeable | Attestor-backed tickets; short TTL |
| Scope creep into CBA | Keep CBA in F1 only |
| Lab code leaks into prod | Hard boundary: no `lab/` in AWX projects |

---

## 9. Explicitly out of scope

- Linux Autopilot / OA3  
- Parallel IdP for M365  
- Replacing SSSD OIDC  
- Keycloak / IdM as Entra substitutes for device CA  
