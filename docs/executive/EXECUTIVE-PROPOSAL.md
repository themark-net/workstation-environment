# Executive Proposal: Linux Zero Trust Workstations

**Program:** Linux Zero Trust (LTZ) — compliance-first  
**Date:** 2026-08-07  
**Audience:** Security architecture, IAM, platform leadership, PMO  

---

## 1. Problem

Windows is accepted as managed because **Entra + Intune compliance + Conditional Access** form a clear device-trust path. Linux already has **SSSD OIDC → Entra** for user login, but **device health is not a first-class CA signal**. Sensitive access either blocks Linux or relies on exceptions.

Passwordless “Hello-class” UX (Entra CBA) is desirable later; it is **not** what unblocks compliant-device decisions today.

---

## 2. Recommendation

Fund a **compliance-first** program on the **existing Microsoft control plane**:

| Priority | Outcome |
|----------|---------|
| **MVP** | Thin attestor + agent → Intune custom compliance → CA **require compliant device** |
| **Future** | Entra CBA / FIDO (no USB), AWX continuous policy, workload certs ± SPIRE, **802.1X machine EAP-TLS** on device certs |

Do **not** build a parallel Linux IdP or Autopilot clone. Network auth reuses the **device** certificate path (not user CBA).

---

## 3. What already exists

- SSSD OIDC + hybrid UID/GID  
- Goldimage admin baselines (SSH, YubiKey)  
- Architecture + lab MVP + production-shaped client trees in `workstation-environment`

---

## 4. Ask

1. Approve **MVP** engineering (attestor, agent, lab evidence, Intune artifacts).  
2. Prioritize **REQ-M*** IAM tickets (Intune enroll, custom compliance, CA compliant device).  
3. Defer **REQ-F*** (CBA) until MVP pilot is green unless org-wide phishing-resistant MFA already mandates it.

---

## 5. Success criteria (MVP)

- Pilot Linux hosts enroll in Intune and reach **Compliant** using attestor-backed custom compliance.  
- Conditional Access grants/denies a pilot app on **compliant device** for those hosts.  
- Fail-closed demo without valid attestation ticket.  
- Client code deployable without lab infrastructure.  
- Design supports **802.1X device EAP-TLS** on the same attestor-gated cert (lab optional; production with enterprise CA + RADIUS).

---

## 6. Cost pointer

See [COST-ESTIMATES.md](COST-ESTIMATES.md). Detailed technical plan: [../implementation/IMPLEMENTATION_PLAN.md](../implementation/IMPLEMENTATION_PLAN.md).
