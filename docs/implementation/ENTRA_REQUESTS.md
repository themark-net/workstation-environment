# Entra / Intune Request Catalog (REQ-M* / REQ-F*)

**Last updated:** 2026-08-07  
**Canonical packets:** [entra-access-requests.md](entra-access-requests.md)

**MVP = device compliance (REQ-M*).** **Future = user CBA / advanced (REQ-F*).**

Do not block device trust on CBA enablement.

---

## MVP requests (device compliance)

| ID | Microsoft term | What to request | Why |
|----|----------------|-----------------|-----|
| **REQ-M01** | Intune Linux enrollment | Allow Linux MDM enrollment for pilot group | Device objects |
| **REQ-M02** | Intune licensing | License pilot users/devices | Enroll capability |
| **REQ-M03** | Compliance policy (Linux built-in) | Encryption, distro, baseline settings | Health signals |
| **REQ-M04** | Custom compliance (Linux) | Upload discovery script + rules JSON | Attestor-backed posture → Compliant |
| **REQ-M05** | Conditional Access (report-only) | Require **compliant device** for pilot apps | Validate |
| **REQ-M06** | Conditional Access (on) | Same after report-only is clean | Enforce |
| **REQ-M07** | CA exclusions / break-glass | Emergency accounts excluded | Safety |
| **REQ-M08** | App registration (optional Graph) | Read device/compliance if automation needs it | Optional |
| **REQ-M09** | Admin consent (if M08) | Application permissions least privilege | Optional |
| **REQ-M10** | Platform documentation | Linux = Intune-enrolled device object; not Autopilot/hybrid join | Architect clarity |

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

- Device/Intune/CA compliant → **REQ-M***  
- CBA / phishing-resistant / SPIRE federation → **REQ-F***  

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

---

## Not in this catalog: 802.1X / RADIUS

Machine **EAP-TLS** is **network/PKI**, not an Entra Conditional Access ticket. Device certs come from attestor + enterprise CA; RADIUS trust is owned with the network team. See [../architecture/device-8021x-eap-tls.md](../architecture/device-8021x-eap-tls.md).

Do **not** file CBA (REQ-F*) as a substitute for device 802.1X.
