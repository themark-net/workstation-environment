# Cost Estimates (Person-Hours) — LZT-WWI

Use these figures in project management tools. Rates are left blank for finance to apply.

**Blended total: ~952 person-hours** including 15% contingency.

---

## By epic

| Epic key (import) | Epic name | Hours | Story points (ref) |
|-------------------|-----------|------:|-------------------:|
| LZT-E1 | P0 Foundations — AWX, repos, goldimage glue | 160 | 34 |
| LZT-E2 | P1 Device trust — Intune + trust agent | 140 | 29 |
| LZT-E3 | P2 Workload identity — MS CA certs + systemd harden | 160 | 34 |
| LZT-E4 | P3 SPIRE platform | 160 | 34 |
| LZT-E5 | P4 User TPM-CBA (no USB) | 180 | 40 |
| LZT-E6 | P5 Enforce Conditional Access + GA readiness | 80 | 18 |
| LZT-E7 | P6 Scale, ops handoff, docs | 48 | 10 |
| | Contingency 15% | 124 | — |
| | **Total** | **952** | **~199 SP** |

Story points use rough 1 SP ≈ 4–5 hours for planning consistency (adjust to team velocity).

---

## By role (approx.)

| Role | Hours | % |
|------|------:|--:|
| Linux / platform engineer | 420 | 44% |
| IAM / Entra coordination | 100 | 11% |
| PKI engineer | 80 | 8% |
| Security engineer / architect | 120 | 13% |
| SPIRE / platform identity | 120 | 13% |
| PM / Scrum facilitation | 48 | 5% |
| Contingency (unallocated) | 64 | 7% |

---

## External lead time (not fully in hours)

| Dependency | Typical calendar lag |
|------------|---------------------|
| App registration / admin consent | 1–3 weeks |
| CBA + CA trust upload | 2–4 weeks |
| Intune custom compliance | 1–2 weeks |
| Workload intermediate + templates | 2–6 weeks |
| Conditional Access change windows | 1–2 weeks |

---

## What is *not* included

- Microsoft license true-ups (assume existing Entra/Intune entitlements)
- Laptop hardware refresh
- 24×7 support expansion
- Full fleet migration beyond pilot+GA wave 1 (add capacity after P6)
