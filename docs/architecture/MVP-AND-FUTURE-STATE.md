# MVP vs Future State

**Status:** Canonical phasing (supersedes earlier CBA-first emphasis)  
**Last updated:** 2026-08-07  
**Urgency order:** **Device compliance** first; passwordless user UX (CBA/Hello-class) later.  
**MVP network:** **802.1X machine EAP-TLS** is part of the device-trust MVP (same attestor-gated device cert), not a Future deferral.

---

## 1. Practical split (non-negotiable)

| Plane | MVP (now) | Future state |
|-------|-----------|--------------|
| **User login on Linux** | SSSD OIDC → Entra (**done**) | Unchanged; optional polish |
| **Device trust** | Enroll + **thin attestor** + compliance agent + Intune custom compliance + CA **require compliant device** | Stronger PCR/MAA; continuous re-attest |
| **User phishing-resistant cloud auth** | **Not required for MVP** — existing MFA strength as org policy allows | **Entra CBA** (TPM PKCS#11, no USB) or FIDO2 — Hello-class hook |
| **Workload identity** | Out of MVP unless a single agent needs a client cert | MS CA workload intermediate; optional SPIRE under MS CA |
| **Network (802.1X)** | **In MVP:** attestor-gated **device** client cert + client EAP-TLS config; **lab FreeRADIUS** proves accept/reject/expire; production-shaped client role ships with agent | Enterprise RADIUS/NPS scale-out, full switch/WLAN fleet cutover (ops), advanced CRL/OCSP automation |
| **Management depth** | Ansible role on client (prod-shaped); AWX later | Full AWX GPO-parity schedules |

**CBA is the passwordless / Hello-class *user* hook.** It is **not** Intune attestation and is **not** on the critical path for “trusted Linux host in Conditional Access.”

**802.1X is machine (device) auth and is MVP.** Use the attestor-gated **device** client cert for EAP-TLS — not the user CBA cert. See [device-8021x-eap-tls.md](device-8021x-eap-tls.md).

---

## 2. MVP outcome

A Linux host can be shown to:

1. **Register** (lab enrollment / birth record; prod: Intune enroll).  
2. **Attest** via thin attestor (TPM/vTPM evidence + health policy).  
3. Receive a **short-lived device ticket/cert** only if attest passes.  
4. Run a **compliance agent** that reports only with that identity.  
5. Feed **Intune-shaped** compliance artifacts (discovery script + rules JSON), with a **mock sink** until tenant access exists.  
6. **Fail closed** at a relying party without a valid ticket.  
7. When tenant allows: real Intune enroll + upload script/JSON + CA require compliant device.  
8. **802.1X EAP-TLS** with the same device cert: lab FreeRADIUS accepts valid certs, rejects missing/expired; client Ansible configures machine EAP-TLS; renew is gated on attestor success (fail closed on the network plane).

**Explicitly out of MVP:** Entra CBA enablement, SPIRE, Keycloak/IdM, full AWX HA, MAA production wiring (optional swap-in later), enterprise-wide switch/WLAN cutover (pilot + lab proof are enough for MVP exit).

---

## 3. Future state outcome

- MVP chain remains (including 802.1X device EAP-TLS path).  
- **User plane:** TPM-backed Entra CBA (no USB) and/or FIDO for phishing-resistant authentication strengths.  
- **Device plane:** PCR golden sets, optional MAA as attestor backend, tighter Intune + CA.  
- **Network plane:** Broad production RADIUS/NPS + access-layer rollout beyond pilot; richer inventory/CRL automation.  
- **Workload plane:** MS CA intermediate ± SPIRE.  
- **Management:** AWX continuous enforce, goldimage assert, policy_gen → compliance.

---

## 4. Trust diagram (MVP)

```text
USER (done)     SSSD OIDC → Entra

DEVICE (MVP)    enroll → thin attestor → short-lived ticket + device client cert
                  → compliance agent → collector / Intune adapter
                  → CA: require compliant device
                  → wpa_supplicant / NM EAP-TLS → RADIUS (lab FreeRADIUS; prod NPS/RADIUS)
                     fail closed when cert expires without renew

ACCESS          Conditional Access evaluates compliant device
                Network access evaluates device cert (machine 802.1X)
                (user MFA strength = existing policy until Future CBA)
```

---

## 5. Related

- [identity-planes-overview.md](identity-planes-overview.md)  
- [REPO-BOUNDARIES.md](REPO-BOUNDARIES.md)  
- [thin-attestor.md](thin-attestor.md)  
- [device-8021x-eap-tls.md](device-8021x-eap-tls.md)  
- [../implementation/ENTRA_REQUESTS.md](../implementation/ENTRA_REQUESTS.md) (MVP vs Future REQ split)  
- [../../client/README.md](../../client/README.md) (production client code)  
- [../../lab/README.md](../../lab/README.md) (lab-only infra)  
