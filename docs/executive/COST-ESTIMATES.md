# Cost Estimates (Man-Hours) — Compliance-First

**Date:** 2026-08-07  
**Unit:** Person-hours (engineering + IAM support coordination, not calendar)

| Phase | Scope | Hours (planning) |
|-------|--------|------------------|
| **M0** Foundations / lab MVP polish | 40–60 |
| **M1** Attestor + agent + collector + Intune artifacts | 120–180 |
| **M2** Tenant plug-in support (REQ-M*, pilot, CA) | 40–80 (mostly wait/IAM) |
| **F1** User CBA / FIDO (optional later) | 80–120 |
| **F2** AWX policy plane | 100–160 |
| **F3** Workload MS CA ± SPIRE | 120–200 |
| **Contingency** | 15% |

**MVP subtotal (M0–M2):** ~200–320 h before contingency.  
**Full program including Future:** scale toward ~1,200–1,500 h only if F1–F3 are all funded.

Solo / LLM-accelerated delivery can compress M0–M1 toward the low end if IAM does not block lab work.
