# Runbook: Device 802.1X EAP-TLS (Machine Auth)

**Plane:** Device (D)  
**Auth method:** EAP-TLS with **device** client certificate  
**Prerequisite architecture:** [../architecture/device-8021x-eap-tls.md](../architecture/device-8021x-eap-tls.md)

---

## 1. Principle

Network access is gated by the **same attestor-backed device identity** used for compliance reporting. User credentials (SSSD OIDC, future CBA) must **not** be the 802.1X identity.

---

## 2. Lab path (optional M1+)

1. Lab CA (or step-ca) issues device client certs after successful `/v1/attest`.  
2. Deploy FreeRADIUS (or existing lab RADIUS) with trust for lab device CA.  
3. Client: NetworkManager or `wpa_supplicant` profile using cert + key from attestor enrollment path (PKCS#11 or file in lab soft mode).  
4. Validate: no cert → reject; valid cert → accept; expired after non-renew → reject.

---

## 3. Production path

1. **PKI:** Device certificate template under enterprise intermediate (sibling of workload intermediate; distinct from user CBA template).  
2. **Issuance:** Attestor success (or CA API called only after attestor success) mints/renews cert; private key in TPM via PKCS#11 where hardware allows.  
3. **RADIUS:** Trust enterprise chain; map device identity to full access VLAN; unknown/revoked → quarantine or deny.  
4. **Client:** Ansible role configures wired/wireless 802.1X (EAP-TLS), cert paths, and renewal timer.  
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
