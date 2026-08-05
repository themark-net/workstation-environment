# Implementation Plan: Linux Zero Trust + Workload Identity

**Program name (suggested):** Linux Zero Trust Workstation & Workload Identity (LZT-WWI)  
**Last updated:** 2026-08-05

---

## 0. Constraints & assumptions

| Item | Assumption |
|------|------------|
| SSSD OIDC + hybrid UID/GID | **Complete** (custom SSSD repo) |
| Goldimage playbooks | **Exist** (SSH + YubiKey admin baseline) |
| Entra / Intune / CA rights | **Limited** — formal requests required ([entra-access-requests.md](entra-access-requests.md)) |
| AWX | **New** open-source AWX instance (not piggyback on unowned tower) |
| SPIRE | **In scope** for platform/workload plane |
| User TPM CBA | In scope; depends on Entra CBA + PKI + broker packages |
| Autopilot for Linux | **Out of scope** |

---

## 1. Phases overview

| Phase | Name | Outcome | Gate |
|-------|------|---------|------|
| **P0** | Foundations | Repos, AWX, goldimage integration, backlog live | AWX healthy; inventories; CI |
| **P1** | Device trust MVP | Intune enroll path + trust agent + custom compliance (report-only) | Devices visible; status.json green on pilot |
| **P2** | Workload certs | MS CA workload intermediate + AWX enroll/renew for agents | Static secrets removed for pilot agents |
| **P3** | SPIRE platform | SPIRE HA + agents on platform; optional UpstreamAuthority | mTLS demo between 2 services |
| **P4** | User TPM-CBA | No-USB Entra CBA on pilot Linux | Sign-in logs show CBA; CA report-only |
| **P5** | Enforce | CA enforce + compliance fail-closed + AWX SLA | Architect acceptance |
| **P6** | Scale / harden | GA fleet, SPIRE on selected clients if needed, docs handoff | Ops runbooks signed |

Phases P1–P4 can partially parallelize once P0 and Entra/PKI requests land.

---

## 2. Workstreams

### WS-A — Platform: AWX

- Deploy AWX OSS (K8s or VM per org standard).
- SSO later (may need Entra **App registration**).
- Inventories: `linux_pilot`, `linux_prod`, `platform`.
- Credentials: SSH (prefer certs from goldimage patterns), vault.
- Job templates: `baseline-enforce`, `baseline-check`, `workload-cert-renew`, `trust-agent`, `spire-agent`.
- Import goldimage playbooks as project or collection dependency.
- SLA: enforce every 1–4h; failed job → ticket + policy_gen stale.

### WS-B — Goldimage integration

- Treat goldimage as **immutable baseline dependency** (SSH, YubiKey admin, admin hardening).
- Do **not** fork; consume versioned tags.
- Layer ZT roles **on top** in ansible-workstation-environment / awx projects.

### WS-C — Device trust (Intune + agent)

- Packages: Intune portal prep, Edge, Identity Broker (version pins).
- `trust_agent` systemd timer → `/var/lib/org-trust/status.json`.
- Custom compliance discovery + JSON rules (**Entra/Intune request**).
- LUKS/encryption + distro built-in compliance.

### WS-D — Workload PKI

- Request **Workload Intermediate** + templates (**PKI / AD CS request**).
- AWX roles: CSR, enroll, install, renew.
- Migrate pilot agents off static tokens.
- Systemd unit hardening playbook.

### WS-E — SPIRE

- Trust domain name, server HA, datastore.
- UpstreamAuthority design with PKI.
- Agents via AWX; registration policies in Git.
- Platform service mTLS pilot.
- Document non-use for human login.

### WS-F — User Entra CBA (TPM, no USB)

- Entra CBA enablement / bindings / CRL (**IAM request**).
- App / permissions only if broker or automation needs Graph (see requests doc).
- tpm2-pkcs11 enrollment UX + automation.
- Pilot users; CA report-only then enforce.

### WS-G — Project delivery

- Jira epics/stories from import pack.
- GitLab issues linked to Jira keys.
- Architecture docs live in this repo.

---

## 3. Dependency graph

```text
[Entra/IAM requests] ──┬──► P4 User CBA
                       ├──► P1 Intune compliance policies
                       └──► P0 AWX Entra SSO (optional)

[PKI Workload Intermediate] ──► P2 Workload certs ──► P3 SPIRE upstream

[Goldimage tags] ──► P0 AWX projects

[P0 AWX] ──► P1, P2, P3, P4 deployability

[P1 compliance report-only] + [P4 CBA pilot] ──► P5 Enforce
```

---

## 4. Pilot definition

- **N = 10–20** Linux workstations (supported Ubuntu and/or RHEL per Intune matrix).
- **Users:** volunteers + platform engineers.
- **Success:** see [linux-zero-trust-entra.md](../runbooks/linux-zero-trust-entra.md) §8 plus workload cert renew proof and SPIRE mTLS demo.

---

## 5. RACI (summary)

| Area | R | A | C | I |
|------|---|---|---|---|
| AWX platform | Linux/Platform | Platform lead | SecOps | IAM |
| Goldimage consume | Linux | Linux lead | Security | — |
| Intune compliance | Linux + Intune admin | IAM/Sec lead | SecOps | Architects |
| PKI workload int. | PKI | IAM/PKI lead | Linux | Security |
| SPIRE | Platform | Platform lead | Security | App teams |
| Entra CBA | IAM | IAM lead | Linux | Security architects |
| CA enforce | SecOps/IAM | CISO/delegate | All | Business |

---

## 6. Risks

| Risk | Mitigation |
|------|------------|
| Entra request lag | Submit all P0 requests in week 1; parallelize non-Entra work |
| PKI template delay | Start SPIRE with temporary internal CA only if approved; migrate upstream |
| TPM-PKCS#11 broker quirks | Spike early (P4 spike story); USB break-glass documented |
| Scope creep (SPIRE on all laptops) | Explicit phase gates; default MS CA certs for agents |
| AWX becomes snowflake | awx-config as code in GitLab |

---

## 7. Exit criteria by phase

Documented in Jira epic descriptions (import pack). Program exit = P5 acceptance + P6 handoff checklist complete.
