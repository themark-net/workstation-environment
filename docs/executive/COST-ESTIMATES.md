# Cost Estimates (Man-Hours) — Compliance-First

**Date:** 2026-08-07  
**Unit:** Person-hours (engineering + IAM support coordination, not calendar)

| Phase | Scope | Hours (planning) |
|-------|--------|------------------|
| **M0** Foundations / lab MVP polish | 40–60 |
| **M1** Attestor + agent + collector + Intune artifacts + **device cert / FreeRADIUS / client 802.1X** | 150–220 |
| **M2** Tenant plug-in support (REQ-M*, pilot, CA) + pilot RADIUS trust | 50–100 (mostly wait/IAM/network) |
| **F1** User CBA / FIDO (optional later) | 80–120 |
| **F2** AWX policy plane | 100–160 |
| **F3** Workload MS CA ± SPIRE | 80–160 |
| **Contingency** | 15% |

**MVP subtotal (M0–M2):** ~240–380 h before contingency.  
**Full program including Future:** scale toward ~1,100–1,400 h only if F1–F3 are all funded.

Solo / LLM-accelerated delivery can compress M0–M1 toward the low end if IAM does not block lab work.
