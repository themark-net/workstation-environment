# Device 802.1X (EAP-TLS) — Network Auth on the Device Plane

**Status:** Architecture extension of compliance-first design  
**Last updated:** 2026-08-07  
**Plane:** **D (Device)** — **not** user CBA (plane H)

---

## 1. Requirement

Corporate wired/wireless must authenticate the **host** with a **device certificate** (machine EAP-TLS). User interactive login (SSSD OIDC / future CBA) is separate.

---

## 2. Fit to existing design

| Component | Role for 802.1X |
|-----------|-----------------|
| Thin attestor | Issues device credential only after posture passes |
| Short-lived device client cert | Same enrollment/attest path; key in TPM/PKCS#11 |
| Enterprise CA chain | RADIUS trusts device intermediate (same family as workload / device PKI) |
| Intune / CA compliant device | Cloud apps; **optional** second gate — network can fail closed on cert alone |
| SSSD OIDC / Entra CBA | **User** plane only — do **not** use user cert for machine 802.1X |

**Do not invent a second trust system.** Extend the attestor-gated device cert and point RADIUS at that CA.

---

## 3. Target flow

```text
enroll → attest (thin attestor) → device client cert (short TTL)
       → wpa_supplicant / NetworkManager EAP-TLS
       → RADIUS validates chain + (optional) inventory/CRL
       → full VLAN | deny / quarantine VLAN if no valid cert
```

Fail closed: no successful attest → no renew → cert expires → network drops or quarantine.

---

## 4. Phasing

| Phase | Scope |
|-------|--------|
| **Design (now)** | Documented; same device plane as compliance |
| **Lab (M1 extension)** | Optional FreeRADIUS + lab CA; demonstrate machine EAP-TLS with attestor-minted cert |
| **Production** | Device intermediate (or shared device/workload intermediate with EKU separation) + RADIUS trust; client Ansible for `wpa_supplicant`/`nm`; renewal timer tied to attestor |

Production 802.1X is **not** on the MVP critical path for **Intune Compliant bit**, but it is a first-class **consumer of the same device cert** once MS CA / internal CA is available (aligns with **F3** device/workload PKI, or earlier if network team requires it).

---

## 5. Design constraints

1. **Machine auth only** — certificate subject/SAN identifies device, not user.  
2. **Short lifetime + renew** off attestor success (match ticket TTL policy).  
3. **Bootstrap** — limited VLAN or one-time bootstrap cert for first enroll/attest (same class as Intune first-boot).  
4. **EKU / template** — Client Authentication; separate from user CBA templates.  
5. **No USB** for day-to-day renewal (TPM-backed key).  
6. **Client config** lives in `ltz-client` Ansible role; no `lab/` dependency in prod.

---

## 6. Related docs

- [thin-attestor.md](thin-attestor.md) — mints device ticket/cert  
- [workload-certs-ms-ca.md](workload-certs-ms-ca.md) — enterprise intermediate pattern (device template sibling)  
- [MVP-AND-FUTURE-STATE.md](MVP-AND-FUTURE-STATE.md) — phasing  
- [identity-planes-overview.md](identity-planes-overview.md) — plane D  
- [../runbooks/device-8021x-eap-tls.md](../runbooks/device-8021x-eap-tls.md) — operational runbook  
