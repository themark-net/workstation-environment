# Entra / Microsoft Identity Request Catalog

**Purpose:** Limited Entra-side access means **every** tenant change is a formal request using Microsoft product terms. Use this catalog when filing tickets to IAM / Cloud Identity.

**Assumption:** User-facing **SSSD OIDC** app registration already provisioned (hybrid identity / UID-GID via customized SSSD + AD hybrid accounts). Do **not** re-request that unless expanding scopes.

---

## How to file

For each row, open an IAM ticket with:

1. **Microsoft term** (exact feature name)  
2. **Environment** (Pilot / Prod tenant)  
3. **Justification** (link epic ID)  
4. **Owners** (Linux platform + IAM)  
5. **Rollback**  
6. **Test plan** (what we can validate with limited access)

---

## REQ-ENH catalog

| ID | Microsoft term | What to request | Why | Phase | Depends on |
|----|----------------|-----------------|-----|-------|------------|
| **REQ-E01** | **App registration** (Microsoft Entra ID) | New confidential/public app for **Linux TPM-CBA enrollment helper** (if automation calls Graph) | CSR inventory, cert status APIs if used | 1 | — |
| **REQ-E02** | **Certificate authorities** (Entra CBA) | Upload/register **enterprise PKI chain** used for **user CBA** (if not already for smart card) | Enable Entra CBA for Linux TPM certs | 1 | Enterprise CA ready |
| **REQ-E03** | **Certificate-based authentication** method | Enable CBA authentication method for pilot security group | Passwordless phishing-resistant login | 1 | REQ-E02 |
| **REQ-E04** | **Authentication binding policy** (CBA) | MFA binding rules for intermediate/OID policy | Count cert auth as MFA strength | 1 | REQ-E03 |
| **REQ-E05** | **Username binding policy** (CBA) | Map cert SAN UPN and/or `certificateUserIds` | User resolution | 1 | REQ-E03 |
| **REQ-E06** | **Certificate user IDs** attribute population | Process/automation rights or IAM runbook to set `certificateUserIds` if high-affinity binding | When SAN UPN not used | 1 | REQ-E05 |
| **REQ-E07** | **Authentication strengths** | Include CBA (and existing FIDO/Hello) in phishing-resistant strength | CA grant control | 1 | REQ-E04 |
| **REQ-E08** | **Conditional Access policy** (report-only) | Pilot: require **compliant device** + **phishing-resistant MFA** for selected cloud apps; include **Linux** platform | Validate without lockout | 1 | Intune Linux, REQ-E07 |
| **REQ-E09** | **Conditional Access policy** (on) | Same as E08 → **On** for pilot group | Enforce | 1 | Pilot success |
| **REQ-E10** | **Microsoft Intune** — Linux enrollment | Confirm MDM authority; enrollment restrictions allow corporate Linux | Device object + compliance | 1 | — |
| **REQ-E11** | **Compliance policy** (Linux) | Built-in: distro, encryption, password | Baseline health | 1 | REQ-E10 |
| **REQ-E12** | **Custom compliance** (Linux) | Discovery script + JSON rules for trust agent status.json | TPM-CBA, policy_gen, workload cert | 1 | REQ-E11 |
| **REQ-E13** | **Microsoft Entra ID app registration** — **Microsoft Graph** application permissions | Minimal Graph for Intune/device read if automation needs it (`DeviceManagement*.Read`, etc.) — **least privilege** | AWX/reporting | 1–2 | Security review |
| **REQ-E14** | **Admin consent** | Tenant admin consent for REQ-E01/E13 | Required for app perms | 1 | E01/E13 |
| **REQ-E15** | **Workload identity federation** | Federated credential on app/managed identity for **SPIRE OIDC issuer** (JWT-SVID) | Phase 3 secret-less Azure access | 3 | SPIRE OIDC provider |
| **REQ-E16** | **Break-glass accounts** exclusion | Exclude emergency accounts from pilot CA | Safety | 1 | E08 |
| **REQ-E17** | **CRL / CDN reachability** | Confirm Entra can fetch enterprise CRL over HTTP | CBA revocation | 1 | E02 |
| **REQ-E18** | **Group-based licensing / Intune license** | Linux pilot users licensed for Intune | Enrollment | 1 | — |
| **REQ-E19** | **Privileged Identity Management** (if used) | PIM for any role that edits CBA/CA | Tier-0 hygiene | 1 | — |
| **REQ-E20** | **Cross-tenant / hybrid** notes | Document hybrid join vs Entra-only device objects for Linux (Linux = Intune enrolled, not classic hybrid AD join) | Architect clarity | 1 | — |

---

## Already done (do not re-request)

| Item | Status |
|------|--------|
| SSSD OIDC **application registration** + permissions | **Done** |
| Hybrid identity path (custom SSSD, UID/GID with AD hybrid accounts) | **Done** (in-house repo) |

---

## Request template (copy/paste)

```text
Title: [Linux ZT] <Microsoft term> — <REQ-ID>

Microsoft product term: <exact>
Tenant: <pilot|prod>
Epic: LTZ-<n>
Justification: Enable Linux fleet Zero Trust parity (user CBA / device compliance / workload federation).

Configuration requested:
- ...

Security:
- Least privilege
- Pilot security group only: <group>
- Rollback: disable method/policy / remove assignment

Validation we will perform (Linux team):
- ...

Dependencies:
- ...
```

---

## Ownership RACI (Entra touchpoints)

| Activity | Linux platform | IAM / Entra admins | Security |
|----------|----------------|--------------------|----------|
| Draft REQ | R | C | C |
| Implement tenant change | C | R | A |
| Pilot validate | R | C | C |
| Prod enable | C | R | A |
