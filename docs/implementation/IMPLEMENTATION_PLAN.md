# Implementation Plan — Linux Zero Trust (Compliance-First)

**Version:** 2.2  
**Date:** 2026-08-07  
**Canonical phasing:** [../architecture/MVP-AND-FUTURE-STATE.md](../architecture/MVP-AND-FUTURE-STATE.md)

---

## 0. Constraints

| Item | Assumption |
|------|------------|
| SSSD OIDC + hybrid UID/GID | **Done** |
| Goldimage (SSH + YubiKey admin) | **Exists** |
| Entra / Intune rights | **Limited** — [ENTRA_REQUESTS.md](ENTRA_REQUESTS.md) |
| Autopilot for Linux | **Out of scope** |
| Entra CBA (Hello-class user) | **Future** — not MVP blocker |
| SPIRE / workload MS CA | **Future** after MVP device trust |
| **802.1X machine EAP-TLS** | **MVP** — same device cert path; lab FreeRADIUS + client role required; prod RADIUS pilot in M2 |

---

## 1. Objectives

### MVP (fund and deliver first)

1. Linux **device trust** accepted under Conditional Access via **compliant device**.  
2. **Thin attestor** + compliance agent so posture is not “local script honesty only.”  
3. Prewritten Intune discovery/rules; plug in when tenant allows.  
4. Production client code (**ltz-client**) has **zero** dependency on lab.  
5. Lab proves enroll → attest → ticket → report → fail-closed.  
6. Lab proves **802.1X EAP-TLS** with attestor-gated device cert (accept / reject / expire).  
7. Production-shaped **802.1X client role** ships with the agent.

### Future (after MVP)

8. Entra **CBA** / FIDO for phishing-resistant **user** auth (no USB day-to-day).  
9. AWX continuous policy (GPO-class).  
10. Workload MS CA intermediate ± SPIRE.  
11. Enterprise-wide 802.1X access-layer scale-out (ops) beyond pilot.

---

## 2. Phase overview

| Phase | Name | Outcome | Calendar (rough) |
|-------|------|---------|------------------|
| **M0** | Foundations | Repos extracted/pinned; lab MVP runnable; RACI | 1–2 weeks |
| **M1** | Device trust MVP | Attestor, agent, collector; Intune artifacts; **device cert + FreeRADIUS + client 802.1X** | 4–6 weeks |
| **M2** | Tenant plug-in | REQ-M* granted; enroll pilot; CA compliant device report-only→on; **pilot RADIUS trust** for device intermediate | Depends on IAM / network |
| **F1** | User CBA / FIDO | REQ-F*; TPM PKCS#11 path | After M2 |
| **F2** | Management depth | New AWX + goldimage assert + policy packs | Parallel/after M1 |
| **F3** | Workload identity | MS CA intermediate ± SPIRE | After M2 |

---

## 3–5. Phases M0–M2

See prior sections: foundations, device trust MVP (no CBA), tenant plug-in REQ-M01–M10.

**Exit M1:** Lab green path includes 802.1X accept/reject/expire evidence.  
**Exit M2:** Pilot Linux hosts show **Compliant**; pilot app CA grants/denies on that bit; pilot network ports/SSID trust device certs where network team enables.

---

## 6. Future phases (summary)

| Phase | Work | REQs |
|-------|------|------|
| **F1** | TPM CBA or FIDO; no USB daily UX | REQ-F01–F08 |
| **F2** | AWX ZT packs, continuous enforce | — |
| **F3** | Workload certs, optional SPIRE, federation | REQ-F10 |

802.1X **client + lab + pilot readiness** live under **M1/M2**, not F3. Scale-out remains ops.

Details: [tpm-cba-no-usb.md](../runbooks/tpm-cba-no-usb.md), [workload-certs-ms-ca.md](../runbooks/workload-certs-ms-ca.md), [spiffe-spire.md](../runbooks/spiffe-spire.md), [device-8021x-eap-tls.md](../runbooks/device-8021x-eap-tls.md).

---

## 7. Repo map

See [dependencies-and-repos.md](dependencies-and-repos.md) and [../architecture/REPO-BOUNDARIES.md](../architecture/REPO-BOUNDARIES.md).

---

## 8. Risks

| Risk | Mitigation |
|------|------------|
| IAM delay on REQ-M* | Lab + mock Intune continues |
| Custom compliance forgeable | Attestor-backed tickets; short TTL |
| Scope creep into CBA | Keep CBA in F1 only |
| Lab code leaks into prod | Hard boundary: no `lab/` in AWX projects |
| 802.1X depends on switch lab hardware | FreeRADIUS + eapol_test / file-mode validation without physical switch |

---

## 9. Explicitly out of scope

- Linux Autopilot / OA3  
- Parallel IdP for M365  
- Replacing SSSD OIDC  
- Keycloak / IdM as Entra substitutes for device CA  

---

## 10. Network access (802.1X) — MVP

Machine **EAP-TLS** uses the **same device client certificate** path as the thin attestor (plane D).

| Layer | MVP delivery |
|-------|----------------|
| Cert mint/renew | Attestor after posture pass |
| Client config | `client/ansible/roles/ltz_8021x` |
| Lab RADIUS | `lab/ansible/roles/lab_radius` via `make ansible-mvp` |
| Prod RADIUS | Network team trusts device intermediate (M2 pilot) |

- Architecture: [../architecture/device-8021x-eap-tls.md](../architecture/device-8021x-eap-tls.md)
- Runbook: [../runbooks/device-8021x-eap-tls.md](../runbooks/device-8021x-eap-tls.md)

Not an Entra REQ-M blocker for Intune Compliant bit; still a **device-plane MVP exit criterion**.
