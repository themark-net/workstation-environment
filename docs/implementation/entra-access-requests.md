# Microsoft Entra / Intune / Graph — Access Request Packets

**Last updated:** 2026-08-07  
**Canonical ID catalog:** [ENTRA_REQUESTS.md](ENTRA_REQUESTS.md) (**REQ-M\*** = MVP device compliance, **REQ-F\*** = Future CBA / advanced).

Use these **Microsoft-termed** packets when filing tickets with limited Entra rights. Prefer one ticket per ID. Track with `blocked::entra` until granted.

**Architecture note:** MVP is **compliant device** (Intune + attestor-backed custom compliance). **Entra CBA** is Future Hello-class *user* auth — do not block device trust on CBA.

---

## How to use

1. Open one ticket **per request ID** (or epic with sub-tasks).  
2. Paste **Request title**, **Microsoft product terms**, **Justification**, **Permissions**, **Environments**, **Owners**.  
3. Attach architecture from [../architecture/MVP-AND-FUTURE-STATE.md](../architecture/MVP-AND-FUTURE-STATE.md).  
4. Reference mapping table below when older tickets used `REQ-ENTRA-*` / `REQ-E*`.

---

## Recommended filing order

### MVP (file first)

1. **REQ-M01 / M02** — Intune Linux enrollment + licenses  
2. **REQ-M03 / M04** — Built-in + **custom compliance** (upload prewritten `client/intune/*`)  
3. **REQ-M05 → M06** — CA **require compliant device** (report-only → on)  
4. **REQ-M07** — Break-glass exclusions  
5. **REQ-M08 / M09** — Optional Graph app (only if collector/automation needs it)  
6. **REQ-M10** — Architect note: Linux = Intune enrolled, not Autopilot/hybrid join  

### Future (do not block MVP)

7. **REQ-F01–F08** — CBA chain, method, binding, auth strength, CA update for phishing-resistant MFA  
8. **REQ-F09** — Optional CBA helper app  
9. **REQ-F10** — SPIRE / workload federation  
10. **REQ-F11** — PIM for CBA/CA admins  

Optional anytime: AWX SSO app (below) — not on device-trust critical path.

---

## MVP packets (device compliance)

### REQ-M01 — Intune Linux enrollment

| Field | Value |
|-------|--------|
| **Microsoft terms** | Microsoft Intune, MDM authority, enrollment restrictions, Linux |
| **Purpose** | Corporate Linux may enroll; device objects for compliance |
| **Actions** | Confirm MDM authority; allow Linux enrollment for pilot group |
| **Maps from** | former REQ-ENTRA-05 (enrollment portion) |

### REQ-M02 — Intune licensing

| Field | Value |
|-------|--------|
| **Microsoft terms** | Group-based licensing, Intune license |
| **Purpose** | Pilot users can enroll |

### REQ-M03 — Linux compliance policy (built-in)

| Field | Value |
|-------|--------|
| **Microsoft terms** | Compliance policy, Linux, encryption, allowed distributions |
| **Purpose** | Baseline health signals |

### REQ-M04 — Custom compliance (Linux)

| Field | Value |
|-------|--------|
| **Microsoft terms** | Custom compliance, discovery script, rules JSON |
| **Purpose** | Map **attestor-backed** posture (`attested`, `ticket_fresh`) → Compliant bit |
| **Artifacts** | `client/intune/discovery.sh`, `client/intune/rules.json` (design repo) |
| **Maps from** | former REQ-ENTRA-05 (custom portion) |

### REQ-M05 / M06 — Conditional Access (compliant device)

| Field | Value |
|-------|--------|
| **Microsoft terms** | Conditional Access, require compliant device, report-only, cloud apps |
| **Purpose** | Gate pilot apps for **Linux + Windows** on **compliant device** |
| **MVP note** | Do **not** require phishing-resistant MFA / CBA unless org already does for all platforms |
| **Maps from** | former REQ-ENTRA-06 (device half only) |

### REQ-M07 — Break-glass exclusions

| Field | Value |
|-------|--------|
| **Microsoft terms** | Conditional Access exclusions, emergency access accounts |

### REQ-M08 / M09 — Graph app (optional)

| Field | Value |
|-------|--------|
| **Microsoft terms** | App registration, application permissions, admin consent |
| **Purpose** | Read device/compliance if automation needs Graph (skip if Intune UI suffices) |
| **Maps from** | former REQ-ENTRA-02 |

### REQ-M10 — Platform documentation

| Field | Value |
|-------|--------|
| **Purpose** | Record: Linux = Intune-enrolled device object; **not** classic hybrid AD join / Autopilot |

---

## Future packets (user CBA / advanced)

### REQ-F01–F05 — CBA enablement & binding

| Field | Value |
|-------|--------|
| **Microsoft terms** | Certificate-based authentication, certificate authorities, authentication binding, username binding, certificateUserIds |
| **Purpose** | Hello-class **user** passwordless to Entra (TPM PKCS#11) — **not** device attestation |
| **Maps from** | former REQ-ENTRA-03, REQ-ENTRA-04, REQ-PKI-02 |

### REQ-F06–F07 — Auth strength + CA update

| Field | Value |
|-------|--------|
| **Microsoft terms** | Authentication strengths, phishing-resistant MFA, Conditional Access |
| **Purpose** | Add phishing-resistant strength **in addition to** compliant device |
| **Maps from** | former REQ-ENTRA-06 (MFA half), REQ-ENTRA-07 |

### REQ-F08 — CRL reachability

| Field | Value |
|-------|--------|
| **Microsoft terms** | CRL, certificate revocation |
| **Purpose** | Entra can fetch enterprise CRL for CBA |

### REQ-F10 — Workload identity federation

| Field | Value |
|-------|--------|
| **Microsoft terms** | Workload identity federation, federated credential |
| **Purpose** | SPIRE OIDC issuer → Azure (later phase) |
| **Maps from** | former REQ-ENTRA-08 |

---

## Optional (not device-trust critical)

### AWX SSO app registration

| Field | Value |
|-------|--------|
| **Microsoft terms** | App registration, OIDC, redirect URI |
| **Purpose** | Admins sign into AWX via Entra |
| **Maps from** | former REQ-ENTRA-01 |

---

## ID mapping (legacy → current)

| Legacy | Current |
|--------|---------|
| REQ-ENTRA-05 / REQ-E10–E12 | **REQ-M01–M04** |
| REQ-ENTRA-06 (device) / REQ-E08–E09 | **REQ-M05–M07** |
| REQ-ENTRA-02 / REQ-E13–E14 | **REQ-M08–M09** |
| REQ-ENTRA-03–04, REQ-PKI-02 / REQ-E02–E07 | **REQ-F01–F08** |
| REQ-ENTRA-07 | **REQ-F06–F07** |
| REQ-ENTRA-08 / REQ-E15 | **REQ-F10** |
| REQ-ENTRA-01 | Optional AWX SSO |

Full tables and RACI: [ENTRA_REQUESTS.md](ENTRA_REQUESTS.md).
