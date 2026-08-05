# Executive Proposal — Linux Zero Trust Parity with Windows (Entra / Intune)

**Document type:** Funding / steering committee  
**Date:** 2026-08-05  
**Program name:** Linux Zero Trust (LTZ)  
**Owner:** Linux Platform (with IAM, Endpoint, Security)

---

## 1. Problem

Windows endpoints are accepted for sensitive access because they participate in a **single decision plane**: Microsoft Entra authentication strengths, Intune compliance, and Conditional Access. Linux endpoints today can authenticate users (SSSD OIDC is **done**) but lack an equivalent, defensible path for:

1. **Phishing-resistant, hardware-bound user authentication** without USB dongles (parity with Windows Hello–class UX).  
2. **Device health as a grant condition** (Intune “compliant device”).  
3. **Continuous configuration reliability** comparable to what architects expect from Entra-managed Windows (not one-time imaging).  
4. **Non-human / agent identity** without static secrets and over-privileged local service accounts.

Without this program, Linux remains a second-class citizen in Conditional Access design, blocking broader Linux adoption for regulated or high-assurance work.

---

## 2. Proposal (one paragraph)

Fund a program that places managed Linux on the **same Entra + Intune + Conditional Access plane** as Windows: **TPM-backed Entra certificate-based authentication (no USB)**, Intune enrollment and compliance (including a host trust agent), and a **new AWX** automation instance that continuously enforces policy (building on our **goldimage** SSH/YubiKey admin baselines and existing **hybrid SSSD**). Extend enterprise PKI with a **workload intermediate** for service certificates, and deploy **SPIRE** in a later phase for attested workload identity—not as a replacement for user login. Entra changes are requested using standard Microsoft feature names and least-privilege app registrations (as done previously for SSSD OIDC).

---

## 3. What we will not do

- Fake Windows Autopilot for Linux  
- Stand up a parallel Linux-only identity provider for corporate SaaS access  
- Require USB security keys for daily Entra passwordless (USB remains break-glass only)  
- Claim SPIRE replaces Hello/CBA for people  

---

## 4. Outcomes & success metrics

| Metric | Target |
|--------|--------|
| Pilot users completing Entra CBA from TPM (no USB) | ≥ 95% of pilot cohort |
| Pilot devices Intune **Compliant** | ≥ 95% |
| Conditional Access pilot: block non-compliant / non-phishing-resistant | Enforced for pilot group |
| AWX policy apply success within SLA | ≥ 98% hosts / rolling 7 days |
| Static secrets removed from pilot agents | ≥ 2 agent types |
| Sev-1 auth lockout incidents attributable to program | 0 (break-glass tested) |

---

## 5. Scope summary

| In scope | Out of scope (later) |
|----------|----------------------|
| New AWX + zt policy packs | Full settings-catalog parity with Windows Intune |
| TPM-CBA, Intune Linux, CA policies | Autopilot-equivalent OEM hash flow |
| Workload MS CA intermediate | Replacing all human AD use cases |
| SPIRE for servers/k8s (phase 2) | SPIRE on every laptop day one |
| Goldimage + sssd-hybrid integration | Rewriting SSSD OIDC (done) |

---

## 6. Investment summary

See [COST_ESTIMATES.md](COST_ESTIMATES.md) for full WBS.

| Category | Man-hours (planning estimate) | Notes |
|----------|-------------------------------|-------|
| Phase 0 Foundations | 160 | AWX, repos, goldimage wiring |
| Phase 1 Device + user ZT | 420 | Intune, agent, TPM-CBA, CA pilot |
| Phase 1b Workload certs | 160 | MS CA intermediate + agents |
| Phase 2 SPIRE | 240 | HA SPIRE + pilot mTLS |
| Phase 3 Federation / GA | 140 | Entra federation, rollout |
| Security / IAM / PM overhead | 180 | Reviews, Entra REQs, agile hygiene |
| **Total** | **~1,300 man-hours** | ~7.5 FTE-months; calendar 4–6 months with parallel streams |

**Contingency:** +15% (195 h) recommended for Entra lead time and hardware TPM variance → **~1,495 h** fully loaded planning number.

**Cash cost (ex-labor):** primarily existing Intune/Entra licenses for pilot users; AWX hosting; optional smart card only for break-glass. No new IdP product required.

---

## 7. Dependencies & risks

| Dependency | Risk if late |
|------------|--------------|
| IAM fulfills Entra CBA / CA / Intune requests | Pilot cannot prove CA path |
| Enterprise PKI templates (user + workload) | No cert issuance |
| Intune licenses for pilot | No compliance bit |
| Hardware with TPM 2.0 | No-USB requirement fails |

Mitigations: early REQ catalog, non-prod PKI lab, pilot hardware allowlist, report-only CA first.

---

## 8. Governance

- **Steering:** Security + IAM + Endpoint + Linux Platform  
- **Agile:** Jira project `LTZ` (see `imports/jira/`)  
- **Code:** GitLab groups linked in stories; issues mirror epics  
- **Change:** Entra/CA changes via REQ-E* tickets only  

---

## 9. Decision requested

Approve **Phase 0–1** funding (~580 h + contingency) and IAM capacity for REQ-E02–E12, with Phase 1b–3 gated on Phase 1 exit criteria.

---

## 10. References

- Architecture: `docs/runbooks/`  
- Implementation: `docs/implementation/IMPLEMENTATION_PLAN.md`  
- Entra request language: `docs/implementation/ENTRA_REQUESTS.md`  
- Imports: `imports/jira/`, `imports/gitlab/`  
