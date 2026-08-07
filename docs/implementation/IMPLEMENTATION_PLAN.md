# Implementation Plan — Linux Zero Trust (Compliance-First)

**Version:** 2.1  
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
| **802.1X machine EAP-TLS** | Same device cert path; lab optional; production with device intermediate + RADIUS |

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
9. **802.1X machine EAP-TLS** on attestor-gated device certs (lab optional; production with device intermediate + RADIUS).

---

## 2. Phase overview

| Phase | Name | Outcome | Calendar (rough) |
|-------|------|---------|------------------|
| **M0** | Foundations | Repos extracted/pinned; lab MVP runnable; RACI | 1–2 weeks |
| **M1** | Device trust MVP | Attestor, agent, collector; Intune artifacts; optional lab RADIUS | 4–6 weeks |
| **M2** | Tenant plug-in | REQ-M* granted; enroll pilot; CA compliant device report-only→on | Depends on IAM |
| **F1** | User CBA / FIDO | REQ-F*; TPM PKCS#11 path | After M2 |
| **F2** | Management depth | New AWX + goldimage assert + policy packs | Parallel/after M1 |
| **F3** | Workload + device network PKI | MS CA intermediate ± SPIRE; **802.1X device EAP-TLS** | After M2 (or earlier if network requires) |

---

## 3–5. Phases M0–M2

See prior sections: foundations, device trust MVP (no CBA), tenant plug-in REQ-M01–M10.

**Exit M2:** Pilot Linux hosts show **Compliant**; pilot app CA grants/denies on that bit.

---

## 6. Future phases (summary)

| Phase | Work | REQs |
|-------|------|------|
| **F1** | TPM CBA or FIDO; no USB daily UX | REQ-F01–F08 |
| **F2** | AWX ZT packs, continuous enforce | — |
| **F3** | Workload certs, optional SPIRE, federation; **device 802.1X EAP-TLS** | REQ-F10; network/RADIUS (not Entra) |

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

---

## 9. Explicitly out of scope

- Linux Autopilot / OA3  
- Parallel IdP for M365  
- Replacing SSSD OIDC  
- Keycloak / IdM as Entra substitutes for device CA  

---

## 10. Network access (802.1X)

Machine **EAP-TLS** uses the **same device client certificate** path as the thin attestor (plane D). Optional lab FreeRADIUS in M1; production aligns with F3 device/workload PKI + RADIUS trust.

- Architecture: [../architecture/device-8021x-eap-tls.md](../architecture/device-8021x-eap-tls.md)
- Runbook: [../runbooks/device-8021x-eap-tls.md](../runbooks/device-8021x-eap-tls.md)

Not an Entra REQ-M blocker for Intune Compliant bit.
