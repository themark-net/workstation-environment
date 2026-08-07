# Runbook: Linux Zero Trust with Microsoft Entra

**Status:** Canonical — **compliance-first MVP**  
**Last updated:** 2026-08-07  

**Urgency:** Device **compliance** over passwordless user UX.  
**CBA** = Future Hello-class *user* hook — **not** Intune device attestation.

Full phasing: [../architecture/MVP-AND-FUTURE-STATE.md](../architecture/MVP-AND-FUTURE-STATE.md).

---

## 1. Executive summary

Linux joins the **same** Entra / Intune / Conditional Access plane as Windows for **device trust**. User login via **SSSD OIDC → Entra is already done**. Phishing-resistant passwordless (TPM CBA) is **optional Future**, not required to mark a host trusted for CA **compliant device** grants.

| Plane | MVP | Future |
|-------|-----|--------|
| User session | SSSD OIDC (done) | + Entra CBA / FIDO |
| Device | Attestor-backed compliance → Intune → CA compliant device | PCR/MAA hardening; **802.1X machine EAP-TLS** |
| Workload | — | MS CA ± SPIRE |
| Management | Ansible client role | AWX continuous |

---

## 2. MVP device chain

```text
enroll → thin attestor → short-lived ticket
  → compliance agent → collector / Intune discovery script
  → Compliant bit → CA require compliant device
```

Code: `client/`, `services/attestor/`, `services/collector/`.  
Lab: `lab/` → `make ansible-mvp`.

---

## 3. Entra requests

- **MVP:** REQ-M* in [../implementation/ENTRA_REQUESTS.md](../implementation/ENTRA_REQUESTS.md)  
- **Future:** REQ-F* same file  

---

## 4. Repo boundaries

[../architecture/REPO-BOUNDARIES.md](../architecture/REPO-BOUNDARIES.md) — production client **never** depends on `lab/`.

---

## Device network auth (802.1X)

Machine **EAP-TLS** uses the **device** client certificate from the attestor path (plane D). Do not use user CBA or SSSD credentials for 802.1X.

- Architecture: [../architecture/device-8021x-eap-tls.md](../architecture/device-8021x-eap-tls.md)  
- Runbook: [device-8021x-eap-tls.md](device-8021x-eap-tls.md)  

Lab: optional RADIUS demo. Production: device intermediate + RADIUS (aligns with F3 PKI).
