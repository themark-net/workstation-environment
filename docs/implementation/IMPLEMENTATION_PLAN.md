# Implementation Plan — Linux Zero Trust (Entra · Intune · AWX · Workload PKI · SPIRE)

**Version:** 1.0  
**Date:** 2026-08-05  
**Repos (logical):**

| Alias | Role |
|-------|------|
| **goldimage** | Existing gold playbooks: common baseline SSH, YubiKey for Linux **admin** accounts |
| **sssd-hybrid** | Customized SSSD (OIDC + hybrid UID/GID with AD hybrid accounts) — **user path done** |
| **workstation-environment** | Architecture, runbooks, import packages (this repo) |
| **zt-awx-config** | *New* GitLab repo: AWX job templates, inventories, Zero Trust policy packs |
| **zt-spire-config** | *New* GitLab repo: SPIRE server/agent manifests, trust domain config |

**Platform assumptions:**

- Deploy **new** AWX (open source / Tower-compatible) instance — not share-prod with unrelated automation if isolation required  
- Limited Entra write access → all tenant changes via [ENTRA_REQUESTS.md](ENTRA_REQUESTS.md)  
- User-facing OIDC SSSD **complete**; do not block on re-doing it  

---

## 1. Objectives

1. Linux clients accepted under same **Conditional Access** posture as Windows (compliant device + phishing-resistant MFA).  
2. **No USB** for day-to-day Entra passwordless: **TPM + Entra CBA**.  
3. Continuous config via **AWX** (GPO-class), goldimage retained for admin baseline.  
4. **Workload MS CA intermediate** for non-user agents; reduce static secrets and over-privileged local service accounts.  
5. **SPIRE** deployed with new AWX for Phase 2 workload fabric (not laptop CBA substitute).  
6. Traceability: **Jira epics/stories** ↔ **GitLab issues** ↔ git repos.

---

## 2. Phase overview

| Phase | Name | Outcome | Rough calendar (sequential) |
|-------|------|---------|------------------------------|
| **0** | Foundations | AWX live, repos, goldimage integrated, RACI | 2–3 weeks |
| **1** | Device + user ZT | Intune, trust agent, TPM-CBA pilot, CA report-only→on | 6–8 weeks |
| **1b** | Workload certs | MS CA intermediate, agent certs, secret retirement | 3–4 weeks (overlap Phase 1) |
| **2** | SPIRE | Servers, agents on servers/k8s first | 4–6 weeks |
| **3** | Federation / scale | Entra workload federation, fleet GA | 3–4 weeks |
| **4** | Hardening & ops | SLOs, runbooks ops, cost optimization | ongoing |

Phases 1 and 1b intentionally overlap after AWX + PKI templates exist.

---

## 3. Phase 0 — Foundations

### 0.1 Repos & branching

| Repo | Contents | Default branch policy |
|------|----------|----------------------|
| goldimage | SSH, YubiKey admin, common baseline | protected main; tag releases |
| sssd-hybrid | Custom SSSD packages/config (existing) | as today |
| workstation-environment | Architecture + imports (this) | protected main |
| zt-awx-config | Inventories, projects, credential docs (no secrets), playbooks/roles | MR required |
| zt-spire-config | SPIRE helm/compose/ansible | MR required |

### 0.2 New AWX instance

- Deploy AWX (K8s or VM per org standard)  
- SSO later optional; initial break-glass local admin  
- Credential types: SSH (from goldimage patterns), Vault/cyberark if available  
- Projects pointing at **zt-awx-config** + **goldimage** (read-only)  
- Instance groups / inventories: `linux_pilot`, `linux_workstations`, `linux_servers`, `spire_infra`  

### 0.3 Integrate goldimage

- Job template: `Gold Baseline — SSH + YubiKey Admin`  
- Runs first on all managed Linux (or assert already applied)  
- Zero Trust packs **never** weaken admin YubiKey/SSH baseline  

### 0.4 Deliverables

- [ ] AWX URL, backup, RBAC  
- [ ] GitLab projects + CI lint (ansible-lint)  
- [ ] Jira project + imported epics  
- [ ] GitLab issues imported with Jira keys in titles  

---

## 4. Phase 1 — Device trust + human TPM-CBA

### 4.1 Image & packages

- Supported distro(s) for Intune  
- Packages: Edge, Identity Broker, tpm2-pkcs11 stack, Intune portal deps  
- Role: `ms_broker_edge`, `intune_prep`, `auth_tpm_cba` (packages only first)

### 4.2 Trust agent + Intune

- Role: `trust_agent` → `/var/lib/org-trust/status.json`  
- File REQ-E10–E12  
- Custom compliance discovery reads status only  

### 4.3 TPM-CBA enrollment path

- Keygen in TPM, CSR, enterprise **user** CA template, NSS/broker  
- Pilot N users (10–20)  
- REQ-E02–E09, E16–E18  

### 4.4 AWX schedules

- Enforce baseline every 1–4h on pilot  
- policy_gen stamped on success  
- Fail compliance if stale  

### 4.5 Exit criteria

- Pilot users: Entra CBA success logs; Intune Compliant; CA report-only clean then On for pilot group  
- No dependency on USB  

---

## 5. Phase 1b — Workload MS CA intermediate

### 5.1 PKI (AD CS / enterprise)

- Create **Workload** intermediate + template  
- SCEP/EST or automation endpoint for AWX  
- Separate from user CBA templates  

### 5.2 Roles

- `workload_ca_trust`, `workload_certs`, `systemd_hardening`  
- Migrate 1–2 agents off static tokens  

### 5.3 Exit criteria

- Renewed certs < 45d lifetime working  
- status.json reflects workload cert health  
- Documented service account reduction for those agents  

---

## 6. Phase 2 — SPIRE

### 6.1 Infra

- SPIRE Server HA + Postgres  
- Trust domain name approved  
- UpstreamAuthority → workload intermediate **or** nested SPIRE root under enterprise PKI  
- Deploy via AWX from **zt-spire-config**  

### 6.2 Agents

- Servers / k8s nodes first  
- Workload registration policies for selected systemd units  
- mTLS between two pilot services  

### 6.3 Exit criteria

- SVID issue/rotate; mTLS verified; runbooks for break-glass  

---

## 7. Phase 3 — Federation & GA

- REQ-E15 workload identity federation  
- Expand CA to broader Linux groups  
- Workstation SPIRE agents only if justified  
- GA checklist from [linux-zero-trust-entra.md](../runbooks/linux-zero-trust-entra.md) success criteria  

---

## 8. Workstream map

| Workstream | Lead skill | Phases |
|------------|------------|--------|
| W1 AWX platform | Platform / SRE | 0 |
| W2 Goldimage integration | Linux admin | 0–1 |
| W3 Intune + compliance | Endpoint / Intune | 1 |
| W4 TPM-CBA + PKI user | IAM + Linux | 1 |
| W5 Workload PKI | PKI + Linux | 1b |
| W6 SPIRE | Platform / security eng | 2–3 |
| W7 Entra requests | IAM (Linux drafts) | 0–3 |
| W8 Security validation | SecOps | 1–3 |

---

## 9. Risk register (summary)

| Risk | Mitigation |
|------|------------|
| Entra request latency | Parallelize REQ drafts early; pilot groups only |
| CBA CRL not reachable | REQ-E17; test revoke |
| TPM model diversity | Hardware allowlist for pilot |
| AWX as SPOF | Backups, restore drill, local break-glass admin access |
| SPIRE scope creep | Phase gate: no SPIRE on VDI fleet until Phase 2 exit |
| Hybrid UID/GID regressions | sssd-hybrid owned tests before policy packs touch auth |

---

## 10. Testing with limited Entra access

| We can do without Entra admin | Needs IAM |
|------------------------------|-----------|
| AWX, goldimage, agents, status.json | CBA enable, CA policies |
| TPM keygen, CSR, **lab CA** | Production CA chain upload to Entra |
| Intune enrollment as licensed user | Tenant-wide compliance assignment |
| Graph read if app granted | App registration + admin consent |

Lab path: stand up **lab enterprise CA** or use existing **non-prod** PKI for CSR practice; production Entra trust only after REQ-E02.

---

## 11. Definition of Done (program)

- [ ] Pilot + GA success criteria (master runbook §8)  
- [ ] All P0/P1 Jira stories Done  
- [ ] GitLab issues closed with links  
- [ ] Ops runbooks handed to support  
- [ ] Cost actuals vs estimate recorded  
