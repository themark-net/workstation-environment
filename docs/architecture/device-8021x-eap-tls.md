# Device 802.1X (EAP-TLS) — Network Auth on the Device Plane

**Status:** **MVP** — first-class device-plane outcome (not Future-only)  
**Last updated:** 2026-08-07  
**Plane:** **D (Device)** — **not** user CBA (plane H)

---

## 1. Requirement

Corporate wired/wireless must authenticate the **host** with a **device certificate** (machine EAP-TLS). User interactive login (SSSD OIDC / future CBA) is separate.

**MVP ships this path end-to-end in lab** (FreeRADIUS + client config + attestor-gated cert) and production-shaped client roles. Enterprise switch/WLAN fleet cutover is ops after pilot, not a reason to leave 802.1X out of MVP.

---

## 2. Fit to existing design

| Component | Role for 802.1X |
|-----------|-----------------|
| Thin attestor | Issues device credential only after posture passes |
| Short-lived device client cert | Same enrollment/attest path; key in TPM/PKCS#11 (lab soft files OK) |
| Enterprise CA chain | RADIUS trusts device intermediate (same family as workload / device PKI) |
| Intune / CA compliant device | Cloud apps; **orthogonal** gate — network fail-closes on cert alone |
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
| **MVP (M1)** | Attestor issues/renews **device client cert** after attest; **client** Ansible role for `wpa_supplicant`/`nm`; **lab FreeRADIUS** trusts lab device CA; validate accept / reject / expire |
| **MVP (M2 pilot)** | Coordinate enterprise RADIUS/NPS trust of device intermediate for pilot ports/SSIDs; same client role, production URLs/CA |
| **Future (scale)** | Full access-layer rollout, advanced CRL/OCSP automation, inventory-driven VLAN mapping |

802.1X is **on the MVP critical path for device trust demos**, independent of the Intune Compliant bit (both consume the same attestor-gated identity).

---

## 5. Design constraints

1. **Machine auth only** — certificate subject/SAN identifies device, not user.  
2. **Short lifetime + renew** off attestor success (match ticket TTL policy).  
3. **Bootstrap** — limited VLAN or one-time bootstrap cert for first enroll/attest (same class as Intune first-boot).  
4. **EKU / template** — Client Authentication; separate from user CBA templates.  
5. **No USB** for day-to-day renewal (TPM-backed key when hardware allows; lab soft key OK).  
6. **Client config** lives in `ltz-client` Ansible role (`ltz_8021x`); no `lab/` dependency in prod.

---

## 6. Related docs

- [thin-attestor.md](thin-attestor.md) — mints device ticket/cert  
- [workload-certs-ms-ca.md](workload-certs-ms-ca.md) — enterprise intermediate pattern (device template sibling)  
- [MVP-AND-FUTURE-STATE.md](MVP-AND-FUTURE-STATE.md) — phasing  
- [identity-planes-overview.md](identity-planes-overview.md) — plane D  
- [../runbooks/device-8021x-eap-tls.md](../runbooks/device-8021x-eap-tls.md) — operational runbook  
