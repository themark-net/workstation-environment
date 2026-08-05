# Cost Estimates (Man-Hours) — Linux Zero Trust Program

**Unit:** man-hours (h)  
**Basis:** single skilled engineer equivalent; split across roles in practice  
**Does not include:** end-user downtime, license list price (assume covered), OEM hardware purchase  

---

## 1. Role rates (for optional $ conversion)

| Role | Suggested $/h (placeholder) | Use |
|------|----------------------------|-----|
| Linux platform | org rate | AWX, agents, TPM |
| IAM / Entra | org rate | REQ implementation |
| Intune / endpoint | org rate | Compliance |
| PKI | org rate | Templates, SCEP |
| Security architecture | org rate | Review |
| PM / Scrum | org rate | Jira/GitLab hygiene |

*Replace placeholders with org bill rates in project software.*

---

## 2. Work breakdown (hours)

### Phase 0 — Foundations (160 h)

| ID | Work package | Hours | Role |
|----|--------------|------:|------|
| P0-01 | Deploy AWX OSS (HA enough for prod pilot), backup, RBAC | 40 | Platform |
| P0-02 | GitLab repos zt-awx-config, zt-spire-config, CI lint | 16 | Platform |
| P0-03 | Wire goldimage project + job template | 16 | Linux |
| P0-04 | Inventories, credential design (no secrets in git) | 16 | Platform |
| P0-05 | Jira project + import epics/stories; GitLab issue import | 24 | PM |
| P0-06 | RACI, runbook review workshop | 16 | Arch + Sec |
| P0-07 | Network/firewall for AWX, CA, CRL paths | 16 | Platform |
| P0-08 | Buffer / unknown | 16 | — |

### Phase 1 — Device + user ZT (420 h)

| ID | Work package | Hours | Role |
|----|--------------|------:|------|
| P1-01 | Roles: intune_prep, ms_broker_edge, package baseline | 40 | Linux |
| P1-02 | trust_agent + systemd timer + status.json schema | 40 | Linux |
| P1-03 | Intune compliance + custom compliance (REQ support) | 32 | Intune |
| P1-04 | auth_tpm_cba packages + enrollment scripts | 56 | Linux |
| P1-05 | User CA template coordination + CSR flow test (lab+prod) | 40 | PKI |
| P1-06 | Entra CBA REQs support, binding, pilot enable | 40 | IAM |
| P1-07 | CA policies report-only → on (pilot) | 24 | IAM |
| P1-08 | AWX schedules, policy_gen, alerting | 32 | Platform |
| P1-09 | Pilot 10–20 users (support, fixes) | 48 | Linux + Help |
| P1-10 | Security test (revoke, lockout, break-glass) | 32 | SecOps |
| P1-11 | Docs / training | 16 | Linux |
| P1-12 | Buffer | 20 | — |

### Phase 1b — Workload certs (160 h)

| ID | Work package | Hours | Role |
|----|--------------|------:|------|
| P1b-01 | Workload intermediate + template + CRL | 32 | PKI |
| P1b-02 | SCEP/EST or enroll API + AWX role | 40 | Linux + PKI |
| P1b-03 | systemd_hardening + migrate 2 agents off static secrets | 40 | Linux |
| P1b-04 | Compliance fields + monitoring expiry | 16 | Linux + Intune |
| P1b-05 | Validation + docs | 16 | Linux |
| P1b-06 | Buffer | 16 | — |

### Phase 2 — SPIRE (240 h)

| ID | Work package | Hours | Role |
|----|--------------|------:|------|
| P2-01 | SPIRE HA design + Postgres + deploy via AWX | 56 | Platform |
| P2-02 | UpstreamAuthority to MS CA workload intermediate | 32 | PKI + Platform |
| P2-03 | Agents on servers/k8s; registration policies | 48 | Platform |
| P2-04 | Pilot mTLS between 2 services | 40 | App + Platform |
| P2-05 | Ops runbooks, backup, restore drill | 24 | Platform |
| P2-06 | Security review | 16 | Sec |
| P2-07 | Buffer | 24 | — |

### Phase 3 — Federation / GA (140 h)

| ID | Work package | Hours | Role |
|----|--------------|------:|------|
| P3-01 | Entra workload identity federation (REQ-E15) | 24 | IAM |
| P3-02 | JWT-SVID OIDC discovery provider | 24 | Platform |
| P3-03 | Expand CA + Intune to GA cohorts | 32 | IAM + Intune |
| P3-04 | Fleet support playbooks, known errors | 24 | Linux |
| P3-05 | GA sign-off evidence pack | 16 | PM + Sec |
| P3-06 | Buffer | 20 | — |

### Cross-cutting (180 h)

| ID | Work package | Hours | Role |
|----|--------------|------:|------|
| XC-01 | Entra request drafting / tracking (all REQ-E*) | 40 | Linux + IAM |
| XC-02 | Architecture updates in workstation-environment | 24 | Arch |
| XC-03 | Agile ceremonies + reporting (program duration) | 48 | PM |
| XC-04 | Cross-team workshops (4× half-day) | 32 | Multi |
| XC-05 | Contingency coordination | 36 | PM |

---

## 3. Totals

| Phase | Hours |
|-------|------:|
| Phase 0 | 160 |
| Phase 1 | 420 |
| Phase 1b | 160 |
| Phase 2 | 240 |
| Phase 3 | 140 |
| Cross-cutting | 180 |
| **Subtotal** | **1,300** |
| Contingency 15% | 195 |
| **Planning total** | **1,495** |

### FTE conversion

| Metric | Value |
|--------|------:|
| Man-hours | 1,495 |
| Man-days (8h) | ~187 |
| Man-months (160h) | ~9.3 |
| Calendar (3 engineers parallel) | ~4–5 months |
| Calendar (2 engineers) | ~5–6 months |

### Suggested project software fields

```text
estimate_hours = <from table>
story_points ≈ hours / 4  (or use hours directly if org prefers)
epic = LTZ-E*
phase = 0|1|1b|2|3
cost_center = <org>
```

---

## 4. Phase gate funding (recommended)

| Gate | Approve hours | Cumulative |
|------|--------------:|-----------:|
| Start Phase 0–1 | 580 | 580 |
| + contingency 15% | 87 | 667 |
| Start Phase 1b (after PKI+AWX ready) | 160 | 827 |
| Start Phase 2 (after Phase 1 exit) | 240 | 1,067 |
| Start Phase 3 | 140 | 1,207 |
| Cross-cutting (spread) | 180 | 1,387 |
| Remaining contingency | ~108 | **~1,495** |
