# Architecture: Identity & Trust Planes (Unified View)

**Status:** Canonical — compliance-first MVP (includes device 802.1X)  
**Last updated:** 2026-08-07  

**Assumptions:**

- User-facing **SSSD OIDC** is **done**.  
- **Goldimage** Ansible playbooks exist for SSH + YubiKey admin.  
- **Limited Entra/Intune access**; tenant changes require formal REQ catalog.  
- **Urgency:** device **compliance** over passwordless user UX.  
- **CBA** is Future-state Hello-class user hook — **not** Intune attestation.  
- **802.1X machine EAP-TLS** is **MVP** on the device plane (same attestor-gated cert).

See [MVP-AND-FUTURE-STATE.md](MVP-AND-FUTURE-STATE.md) and [REPO-BOUNDARIES.md](REPO-BOUNDARIES.md).

---

## Planes

```text
PLANE H — HUMAN (user)
  MVP:  SSSD OIDC → Entra (DONE)
  Future: Entra CBA via platform TPM PKCS#11 (no USB)
  Admin: YubiKey path (goldimage) — EXISTS

PLANE D — DEVICE (laptop/workstation)     ★ MVP CRITICAL PATH
  Enroll (Intune in prod; lab birth record)
  Thin attestor → short-lived device ticket/cert
  Compliance agent → collector / Intune custom compliance artifacts
  Conditional Access: require compliant device
  Network: **802.1X EAP-TLS** uses the **same device cert** (machine auth) — MVP
           Lab FreeRADIUS required for MVP proof; prod RADIUS/NPS for pilot

PLANE W — WORKLOAD (non-human)            Future / selective
  MS CA Workload Intermediate; optional SPIRE under MS CA
  (Device 802.1X certs are plane D — sibling template, not user CBA)

PLANE M — MANAGEMENT
  MVP: Ansible roles from ltz-client (prod-shaped), including 802.1X client role
  Future: AWX continuous policy (GPO parity)
```

---

## What is / is not Intune attestation

| Component | Role |
|-----------|------|
| Thin attestor + compliance agent | **Device posture verification** (MVP) |
| Intune custom compliance | **Maps** verified posture → Compliant bit |
| Entra CBA | **User** cert auth to Entra (Future) |
| SSSD OIDC | **User** session identity on Linux (Done) |
| Device cert + 802.1X EAP-TLS | **Machine** network auth (plane D, **MVP**) — not user CBA |

---

## Trust decisions

1. **MVP success** = compliant device path with attestor-backed claims **and** machine 802.1X on the same device cert — not CBA.  
2. **No parallel IdP** for corporate user access.  
3. **SSSD OIDC does not equal device trust.**  
4. **Custom compliance is necessary but not sufficient** without attestor-backed evidence.  
5. **Client code must run without lab/** dependencies.  
6. SPIRE/CBA/MAA are **Future** upgrades to the same chain shape.  
7. **802.1X machine auth** is MVP: consumes the device cert from the attestor path; it is not a parallel PKI and not user CBA. See [device-8021x-eap-tls.md](device-8021x-eap-tls.md).  
