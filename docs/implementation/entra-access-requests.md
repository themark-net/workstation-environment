# Microsoft Entra / Intune / Graph — Access Request Catalog

Use these **Microsoft-termed** request packets when you have limited Entra rights (same pattern as SSSD OIDC **App registration**). Copy into ServiceNow/Jira/IAM intake.

---

## How to use

1. Open one ticket **per request ID** (or one epic with sub-tasks).
2. Paste **Request title**, **Microsoft product terms**, **Justification**, **Permissions**, **Environments**, **Owners**.
3. Attach architecture one-pager from [EXECUTIVE-PROPOSAL.md](../executive/EXECUTIVE-PROPOSAL.md).
4. Track ticket IDs in GitLab issue labels `blocked::entra` until granted.

---

## REQ-ENTRA-01 — Application registration: AWX SSO (optional P0/P1)

| Field | Value |
|-------|--------|
| **Microsoft terms** | App registration, Enterprise application, OpenID Connect, redirect URI, single sign-on |
| **Purpose** | Administrators sign into AWX via Entra ID |
| **Permissions (Graph)** | Delegated: `openid`, `profile`, `email`; optionally `User.Read` |
| **Redirect URIs** | `https://<awx-host>/sso/...` (exact paths per AWX OIDC docs) |
| **Who needs admin** | Application Administrator or Cloud Application Administrator to create app; AWX admins consume client ID/secret or federated credential |
| **Secret handling** | Prefer certificate credential or federated identity; if client secret, vault in AWX, 90-day rotation |
| **Similar to** | Existing SSSD OIDC application (reference that app ID) |

---

## REQ-ENTRA-02 — Application registration: automation / Graph for device or compliance reporting (optional)

| Field | Value |
|-------|--------|
| **Microsoft terms** | App registration, Application permissions, Microsoft Graph, admin consent |
| **Purpose** | Read device compliance / inventory for dashboards (if not using Intune portal alone) |
| **Permissions** | Application: `DeviceManagementManagedDevices.Read.All` and/or `DeviceManagementConfiguration.Read.All` — **least privilege**; justify each |
| **Admin consent** | Required for application permissions |
| **Alternative** | Skip app; use Intune UI + export for pilot (reduces scope) |

---

## REQ-ENTRA-03 — Certificate-based authentication (CBA) enablement

| Field | Value |
|-------|--------|
| **Microsoft terms** | Certificate-based authentication, authentication methods policy, authentication binding, username binding, certificateUserIds, CRL |
| **Purpose** | Linux users authenticate to Entra with X.509 certs (TPM-held keys) |
| **Actions requested** | Enable CBA authentication method for group `sg-linux-cba-pilot`; configure trusted CAs; HTTP CRL endpoints; username binding policy; authentication binding (MFA) for issuer/policy OID |
| **Roles** | Authentication Policy Administrator / Authentication Administrator / Global Administrator (per tenant model) |
| **Dependencies** | Enterprise CA chain + CRL reachable from Microsoft cloud |
| **Not requested** | Disabling passwords tenant-wide |

---

## REQ-ENTRA-04 — Upload / trust enterprise CA for CBA

| Field | Value |
|-------|--------|
| **Microsoft terms** | Certificate authorities, public key infrastructure, CRL, delta CRL, authentication methods > certificate-based authentication |
| **Purpose** | Entra trusts User/CBA issuing chain |
| **Deliverables from PKI** | Root + intermediate CER/PEM, CRL URLs (HTTP) |
| **Roles** | Same as CBA admin |

---

## REQ-ENTRA-05 — Intune Linux enrollment & compliance

| Field | Value |
|-------|--------|
| **Microsoft terms** | Microsoft Intune, Linux enrollment, Company Portal / Intune app for Linux, compliance policy, custom compliance detection script, device compliance |
| **Purpose** | Enroll Linux workstations; evaluate compliance; feed Conditional Access |
| **Actions** | Enable Linux MDM authority as required; create compliance policies (distro, encryption); create **custom compliance** for trust agent JSON; assign to pilot group |
| **Roles** | Intune Administrator / Endpoint Administrator |
| **Groups** | `sg-linux-intune-pilot` (users/devices) |

---

## REQ-ENTRA-06 — Conditional Access policies (report-only then on)

| Field | Value |
|-------|--------|
| **Microsoft terms** | Conditional Access, grant controls, require multifactor authentication, authentication strength, require device to be marked compliant, report-only mode, break-glass accounts |
| **Purpose** | Gate M365/LOB apps: phishing-resistant + compliant device for Linux+Windows |
| **Actions** | Create CA policies in **report-only**; include pilot users; exclude break-glass; later switch to on |
| **Authentication strength** | Include CBA and existing phishing-resistant methods |
| **Roles** | Conditional Access Administrator / Security Administrator |

---

## REQ-ENTRA-07 — Identity Broker / PRMFA prerequisites (if tenant settings required)

| Field | Value |
|-------|--------|
| **Microsoft terms** | Microsoft Identity Broker (Linux), phishing-resistant MFA, certificate authentication, SSO extension |
| **Purpose** | Broker-mediated cert auth on Linux desktops |
| **Actions** | Confirm tenant features; document supported broker version; any required enterprise app assignments for broker |
| **Roles** | IAM + desktop engineering |

---

## REQ-ENTRA-08 — Workload identity federation (SPIRE JWT-SVID) — later phase

| Field | Value |
|-------|--------|
| **Microsoft terms** | Workload identity federation, federated identity credential, app registration or user-assigned managed identity, OIDC issuer |
| **Purpose** | Non-human workloads exchange SPIRE JWT-SVID for Entra tokens (Azure/Graph) without secrets |
| **Not for** | Interactive user login |
| **Phase** | P3+ after SPIRE OIDC discovery provider exists |

---

## REQ-PKI-01 — Workload Intermediate CA + templates

| Field | Value |
|-------|--------|
| **Microsoft / PKI terms** | AD CS, subordinate/intermediate CA, certificate template, Client Authentication EKU, SCEP/NDE/EST/CEP (as applicable), auto-enrollment or API issuance |
| **Purpose** | Issue host/service certs for Linux agents; optional SPIRE upstream |
| **Separate from** | User smart card / CBA templates |
| **Owners** | PKI team |

---

## REQ-PKI-02 — User CBA certificate template for TPM PKCS#11 enrollment

| Field | Value |
|-------|--------|
| **Terms** | User template, Client Authentication, subject UPN SAN, short validity, non-exportable (client-enforced via TPM) |
| **Purpose** | Sign CSRs from Linux TPM-backed keys |
| **Issuance path** | Manual/API/SCEP as designed — **not** Windows auto-enroll GPO |

---

## Request sequence (week 1)

1. REQ-PKI-01, REQ-PKI-02 (longest lead)  
2. REQ-ENTRA-03, REQ-ENTRA-04 (CBA)  
3. REQ-ENTRA-05 (Intune)  
4. REQ-ENTRA-06 (CA report-only)  
5. REQ-ENTRA-01 (AWX SSO) if needed  
6. REQ-ENTRA-02 only if dashboards need Graph  
7. REQ-ENTRA-08 deferred  

---

## Evidence to attach

- Link to this repo architecture docs  
- Pilot group names  
- CRL reachability test plan  
- Reference: existing SSSD OIDC app registration (working precedent)
