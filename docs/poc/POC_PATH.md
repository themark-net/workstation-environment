# POC Path (Lab) — Compliance-First + Device 802.1X

**Aligned to compliance-first MVP** (attestor + compliance + **machine 802.1X**). CBA is out of POC critical path.

Document lab evidence for the device trust chain without depending on new Entra privileges beyond what already exists for testing.

Canonical architecture: [../architecture/MVP-AND-FUTURE-STATE.md](../architecture/MVP-AND-FUTURE-STATE.md).

## Objectives (checklist)

- [ ] Enroll lab host into attestor (birth record)  
- [ ] Attest with vTPM/lab evidence → short-lived ticket **and device client cert**  
- [ ] Agent reports only with valid ticket  
- [ ] Mock Intune / discovery JSON reflects attested + ticket_fresh  
- [ ] Fail-closed at lab RP without ticket  
- [ ] Client role installable without lab paths hard-coded  
- [ ] **802.1X:** FreeRADIUS trusts lab device CA; workstation EAP-TLS profile present  
- [ ] **802.1X:** Valid cert accepted; missing/expired cert rejected  

Lab deploy: [../../lab/README.md](../../lab/README.md).

---

## 802.1X lab path (MVP)

Part of the MVP happy-path (not optional):

1. Attestor device CA issues short-lived **device client cert** post-attest.  
2. FreeRADIUS trusts lab device CA.  
3. Workstation uses `wpa_supplicant` / NM EAP-TLS with that cert (`ltz_8021x` role).  
4. Without renew after attest failure, access drops.

Design: [../architecture/device-8021x-eap-tls.md](../architecture/device-8021x-eap-tls.md).  
Runbook: [../runbooks/device-8021x-eap-tls.md](../runbooks/device-8021x-eap-tls.md).
