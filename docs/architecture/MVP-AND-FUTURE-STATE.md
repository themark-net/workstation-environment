# MVP vs Future State

**Status:** Canonical phasing (supersedes earlier CBA-first emphasis)  
**Last updated:** 2026-08-07  
**Urgency order:** **Device compliance** first; passwordless user UX (CBA/Hello-class) later.

---

## 1. Practical split (non-negotiable)

| Plane | MVP (now) | Future state |
|-------|-----------|--------------|
| **User login on Linux** | SSSD OIDC → Entra (**done**) | Unchanged; optional polish |
| **Device trust** | Enroll + **thin attestor** + compliance agent + Intune custom compliance + CA **require compliant device** | Stronger PCR/MAA; continuous re-attest |
| **User phishing-resistant cloud auth** | **Not required for MVP** — existing MFA strength as org policy allows | **Entra CBA** (TPM PKCS#11, no USB) or FIDO2 — Hello-class hook |
| **Workload identity** | Out of MVP unless a single agent needs a client cert | MS CA workload intermediate; optional SPIRE under MS CA |
| **Management depth** | Ansible role on client (prod-shaped); AWX later | Full AWX GPO-parity schedules |

**CBA is the passwordless / Hello-class *user* hook.** It is **not** Intune attestation and is **not** on the critical path for “trusted Linux host in Conditional Access.”

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

**Explicitly out of MVP:** Entra CBA enablement, SPIRE, Keycloak/IdM, full AWX HA, MAA production wiring (optional swap-in later).

---

## 3. Future state outcome

- MVP chain remains.  
- **User plane:** TPM-backed Entra CBA (no USB) and/or FIDO for phishing-resistant authentication strengths.  
- **Device plane:** PCR golden sets, optional MAA as attestor backend, tighter Intune + CA.  
- **Workload plane:** MS CA intermediate ± SPIRE.  
- **Management:** AWX continuous enforce, goldimage assert, policy_gen → compliance.

---

## 4. Trust diagram (MVP)

```text
USER (done)     SSSD OIDC → Entra

DEVICE (MVP)    enroll → thin attestor → short-lived ticket/cert
                  → compliance agent → collector / Intune adapter
                  → CA: require compliant device

ACCESS          Conditional Access evaluates compliant device
                (user MFA strength = existing policy until Future CBA)
```

---

## 5. Related

- [identity-planes-overview.md](identity-planes-overview.md)  
- [REPO-BOUNDARIES.md](REPO-BOUNDARIES.md)  
- [thin-attestor.md](thin-attestor.md)  
- [../implementation/ENTRA_REQUESTS.md](../implementation/ENTRA_REQUESTS.md) (MVP vs Future REQ split)  
- [../../client/README.md](../../client/README.md) (production client code)  
- [../../lab/README.md](../../lab/README.md) (lab-only infra)  
