# MVP vs Future State

**Status:** Canonical phasing  
**Last updated:** 2026-08-11  
**Urgency order:** **Device compliance** first; passwordless user UX (CBA/Hello-class) later.

---

## 1. Practical split (non-negotiable)

| Plane | MVP (now) | Future state |
|-------|-----------|--------------|
| **User login on Linux** | SSSD OIDC → Entra (**done** in design; **staging tenant test next**) | Optional polish; CBA later |
| **Device trust** | Enroll + **thin attestor** + compliance agent + Intune custom compliance + CA **require compliant device** | Stronger PCR/MAA; continuous re-attest |
| **Disk encryption** | **TPM + LUKS baseline** on hosts (`ltz_tpm_luks` role; Intune `disk_encrypted` claim) | PCR policy hardening, remote recovery escrow |
| **User phishing-resistant cloud auth** | **Not required for MVP** — existing MFA as org policy allows | **Entra CBA** (TPM PKCS#11, no USB) or FIDO2 |
| **Workload identity** | Out of MVP unless a single agent needs a client cert | MS CA workload intermediate; optional SPIRE under MS CA |
| **Network (802.1X)** | **Lab MVP proven** (ticket-gated device cert + FreeRADIUS EAP-TLS); same client path for pilot | Enterprise RADIUS/NPS fleet scale-out |
| **Management depth** | Ansible roles on client (prod-shaped); AWX later | Full AWX GPO-parity schedules |

**CBA is the passwordless / Hello-class *user* hook.** It is **not** Intune attestation and is **not** on the critical path for “trusted Linux host in Conditional Access.”

**802.1X is machine (device) auth.** Use the attestor-gated **device** client cert for EAP-TLS — not the user CBA cert. See [device-8021x-eap-tls.md](device-8021x-eap-tls.md).

---

## 2. MVP outcome

A Linux host can be shown to:

1. **Register** (lab enrollment / birth record; prod: Intune enroll).  
2. **Attest** via thin attestor (TPM/vTPM evidence + health policy).  
3. Receive a **short-lived device ticket** only if attest passes.  
4. Run a **compliance agent** that reports only with that identity.  
5. Feed **Intune-shaped** compliance artifacts (discovery + rules), including **disk_encrypted**.  
6. **Fail closed** at a relying party without a valid ticket.  
7. **Encrypt** data at rest via **LUKS**, preferably **TPM-bound** unlock (`ltz_tpm_luks`).  
8. When tenant allows: Intune enroll + CA require compliant device.  
9. **802.1X EAP-TLS** with ticket-gated device cert (lab proven; pilot RADIUS when network ready).  
10. **User login** via SSSD OIDC against the real tenant (staging next if not already re-validated).

**Explicitly out of MVP:** Entra CBA enablement, SPIRE, Keycloak/IdM, full AWX HA, MAA production wiring (optional swap-in later), enterprise-wide switch cutover.

---

## 3. Future state outcome

- MVP chain remains (including lab/pilot 802.1X and TPM LUKS).  
- **User plane:** TPM-backed Entra CBA (no USB) and/or FIDO.  
- **Device plane:** PCR golden sets, optional MAA as attestor backend.  
- **Network plane:** Broad production RADIUS/NPS + access-layer rollout.  
- **Workload plane:** MS CA intermediate ± SPIRE.  
- **Management:** AWX continuous enforce.

---

## 4. Trust diagram (MVP)

```text
USER            SSSD OIDC → Entra  (done / re-stage on tenant)
DISK            LUKS (+ TPM unlock) → disk_encrypted claim

DEVICE (MVP)    enroll → thin attestor → short-lived ticket
                  → compliance agent → collector / Intune adapter
                  → CA: require compliant device
                  → device cert (ticket-gated) → 802.1X EAP-TLS (lab proven)

ACCESS          Conditional Access evaluates compliant device
                Network evaluates device cert (machine 802.1X)
```

---

## 5. Related

- [identity-planes-overview.md](identity-planes-overview.md)  
- [REPO-BOUNDARIES.md](REPO-BOUNDARIES.md)  
- [thin-attestor.md](thin-attestor.md)  
- [device-8021x-eap-tls.md](device-8021x-eap-tls.md)  
- [../runbooks/tpm-luks-disk-encryption.md](../runbooks/tpm-luks-disk-encryption.md)  
- [../deployment/sssd-oidc-staging.md](../deployment/sssd-oidc-staging.md)  
- [../deployment/entra-azure-checklist.md](../deployment/entra-azure-checklist.md)  
