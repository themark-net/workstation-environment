# Runbook: Device 802.1X EAP-TLS (Machine Auth)

**Plane:** Device (D)  
**Auth method:** EAP-TLS with **device** client certificate  
**MVP status:** Required for lab MVP green path; production-shaped client role ships with agent  
**Prerequisite architecture:** [../architecture/device-8021x-eap-tls.md](../architecture/device-8021x-eap-tls.md)

---

## 1. Principle

Network access is gated by the **same attestor-backed device identity** used for compliance reporting. User credentials (SSSD OIDC, future CBA) must **not** be the 802.1X identity.

---

## 2. Lab path (MVP — required)

1. Thin attestor issues short-lived **device client certs** after successful `/v1/attest` (device CA enabled).  
2. FreeRADIUS on `lab_rp` trusts the lab device CA (`lab_radius` role).  
3. Client: `ltz_8021x` + agent install cert under `/var/lib/ltz-trust/device.*`; NetworkManager/`wpa_supplicant` EAP-TLS profile.  
4. Validate (also covered by `make validate`):  
   - no cert → RADIUS reject  
   - valid cert → accept  
   - expired after non-renew → reject  

Deploy via:

```bash
cd lab && make ansible-mvp && make validate
```

---

## 3. Production path (MVP pilot readiness)

1. **PKI:** Device certificate template under enterprise intermediate (sibling of workload intermediate; distinct from user CBA template).  
2. **Issuance:** Attestor success (or CA API called only after attestor success) mints/renews cert; private key in TPM via PKCS#11 where hardware allows.  
3. **RADIUS:** Trust enterprise chain; map device identity to full access VLAN; unknown/revoked → quarantine or deny.  
4. **Client:** Ansible role `ltz_8021x` configures wired/wireless 802.1X (EAP-TLS), cert paths, and renewal via trust agent timer.  
5. **CRL/OCSP:** Ensure RADIUS can check revocation on short-lived certs (or rely on very short TTL).

---

## 4. Bootstrap

First boot needs either:

- Quarantine / onboarding VLAN with path to attestor + CA only, or  
- One-time bootstrap credential replaced immediately after first successful attest.

Document the chosen path with network engineering; do not leave long-lived bootstrap certs on production hosts.

---

## 5. Separation checklist

| Item | Correct | Incorrect |
|------|---------|-----------|
| 802.1X identity | Device cert | User smart card / CBA cert |
| Issuance gate | Attestor (posture) | Open enrollment |
| Cloud apps | Intune compliant + CA | Network cert alone as Entra proof |
| Renewal | Attestor loop | Manual USB / perpetual cert |

---

## 6. Ops signals

- RADIUS accept/reject rates by device inventory  
- Cert expiry approaching without renew (attestor or agent unhealthy)  
- Correlation: hosts non-compliant in Intune should not keep long network access if policy ties renew to posture  
