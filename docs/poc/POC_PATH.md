# POC Path (Lab) — Compliance-First

**Aligned to compliance-first MVP** (attestor + compliance). CBA is out of POC critical path.

Document lab evidence for the device trust chain without depending on new Entra privileges beyond what already exists for testing.

Canonical architecture: [../architecture/MVP-AND-FUTURE-STATE.md](../architecture/MVP-AND-FUTURE-STATE.md).

## Objectives (checklist)

- [ ] Enroll lab host into attestor (birth record)  
- [ ] Attest with vTPM/lab evidence → short-lived ticket  
- [ ] Agent reports only with valid ticket  
- [ ] Mock Intune / discovery JSON reflects attested + ticket_fresh  
- [ ] Fail-closed at lab RP without ticket  
- [ ] Client role installable without lab paths hard-coded  

Lab deploy: [../../lab/README.md](../../lab/README.md).

---

## Optional: 802.1X lab extension

After MVP happy-path (attest → ticket → fail-closed):

1. Lab CA issues short-lived **device client cert** post-attest.  
2. FreeRADIUS trusts lab CA.  
3. Workstation uses `wpa_supplicant` EAP-TLS with that cert.  
4. Without renew after attest failure, access drops.

Not required to close Intune compliance POC. Design: [../architecture/device-8021x-eap-tls.md](../architecture/device-8021x-eap-tls.md).
