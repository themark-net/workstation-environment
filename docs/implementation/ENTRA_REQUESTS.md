# Entra / Microsoft Identity Request Catalog

**Purpose:** Formal Microsoft-termed tickets for IAM / Cloud Identity.  
**Last updated:** 2026-08-07  
**Phasing:** **MVP** (device compliance) vs **Future** (CBA / advanced).

**Already done — do not re-request:** SSSD OIDC app registration; hybrid UID/GID SSSD path.

---

## How to file

1. Microsoft product term (exact)  
2. Environment (Pilot / Prod)  
3. Justification + epic  
4. Owners (Linux platform + IAM)  
5. Rollback  
6. Test plan  

---

## MVP requests (device compliance path)

| ID | Microsoft term | What to request | Why | Depends on |
|----|----------------|-----------------|-----|------------|
| **REQ-M01** | **Microsoft Intune** — Linux enrollment | MDM authority; enrollment restrictions allow corporate Linux | Device object | — |
| **REQ-M02** | **Group-based licensing / Intune license** | Pilot users licensed for Intune | Enrollment | M01 |
| **REQ-M03** | **Compliance policy** (Linux) | Built-in: distro, encryption, password as needed | Baseline health | M01 |
| **REQ-M04** | **Custom compliance** (Linux) | Discovery script + JSON rules (prewritten artifacts from `ltz-client`) | Attestor-backed posture → Compliant bit | M03 |
| **REQ-M05** | **Conditional Access policy** (report-only) | Pilot: **require compliant device** for selected apps; include **Linux** | Validate without lockout | M04 |
| **REQ-M06** | **Conditional Access policy** (on) | Same as M05 → **On** for pilot group | Enforce | M05 pilot clean |
| **REQ-M07** | **Break-glass accounts** exclusion | Exclude emergency accounts from pilot CA | Safety | M05 |
| **REQ-M08** | **Microsoft Entra ID app registration** + **Graph** (optional) | Least-privilege device/compliance read or notes if collector pushes signals | Automation | Security review |
| **REQ-M09** | **Admin consent** | For M08 if used | App perms | M08 |
| **REQ-M10** | **Documentation note** | Linux = Intune enrolled device object; **not** classic hybrid AD join / Autopilot | Architect clarity | — |

### MVP CA policy note

MVP Conditional Access should emphasize **compliant device**.  
Do **not** block MVP on **phishing-resistant MFA / CBA** unless org policy already requires it for all platforms.

---

## Future requests (user passwordless / Hello-class + advanced)

| ID | Microsoft term | What to request | Why |
|----|----------------|-----------------|-----|
| **REQ-F01** | **Certificate authorities** (Entra CBA) | Upload enterprise **user/CBA** chain | Enable CBA |
| **REQ-F02** | **Certificate-based authentication** method | Enable CBA for pilot group | Passwordless user auth |
| **REQ-F03** | **Authentication binding policy** (CBA) | MFA binding for intermediate | Strength |
| **REQ-F04** | **Username binding policy** (CBA) | SAN UPN / certificateUserIds | User resolution |
| **REQ-F05** | **Certificate user IDs** population | If high-affinity binding | Optional |
| **REQ-F06** | **Authentication strengths** | Include CBA (+ FIDO/Hello) in phishing-resistant strength | CA grant |
| **REQ-F07** | **Conditional Access** update | Add phishing-resistant MFA **in addition to** compliant device | Full parity |
| **REQ-F08** | **CRL reachability** | Entra can fetch enterprise CRL | Revocation |
| **REQ-F09** | **App registration** (optional CBA helper) | Graph for cert inventory if needed | Automation |
| **REQ-F10** | **Workload identity federation** | SPIRE OIDC issuer federated credential | Phase workload |
| **REQ-F11** | **PIM** for CBA/CA admin roles | Tier-0 hygiene | Optional |

---

## Retired / remapped IDs

Earlier REQ-E01–E20 mapped as:

- Device/Intune/CA compliant → **REQ-M\***  
- CBA / phishing-resistant / SPIRE federation → **REQ-F\***  

---

## Request template

```text
Title: [Linux ZT][MVP|Future] <Microsoft term> — <REQ-ID>

Microsoft product term: <exact>
Tenant: <pilot|prod>
Phase: MVP | Future
Epic: LTZ-<n>
Justification: <device compliance | user CBA | workload federation>

Configuration requested:
- ...

Security:
- Least privilege
- Pilot group only: <group>
- Rollback: ...

Validation (Linux team):
- ...
```

---

## RACI

| Activity | Linux platform | IAM | Security |
|----------|----------------|-----|----------|
| Draft REQ | R | C | C |
| Implement tenant change | C | R | A |
| Pilot validate | R | C | C |
| Prod enable | C | R | A |
