# POC Path — Device Trust Without New Entra Levers

**Status:** Neutral engineering POC  
**Aligned to:** compliance-first MVP (attestor + compliance). CBA is out of POC critical path.

See [../architecture/MVP-AND-FUTURE-STATE.md](../architecture/MVP-AND-FUTURE-STATE.md).

---

## Goal

Prove: enroll → attest → short-lived ticket → compliance report → fail-closed, using lab infrastructure only.

## Optional: 802.1X lab extension

Not required to close core POC (compliance chain), but validates network consumer of device cert:

- [ ] Lab CA issues device client cert only after successful attest  
- [ ] `wpa_supplicant` / NM EAP-TLS against FreeRADIUS  
- [ ] Reject without cert; accept with valid cert; reject after expiry without renew  

See [../architecture/device-8021x-eap-tls.md](../architecture/device-8021x-eap-tls.md).

**Note:** Full historical POC checklist content may live in git history; this file prioritizes current MVP alignment + 802.1X extension. Expand from lab README and prior POC commits as needed.
