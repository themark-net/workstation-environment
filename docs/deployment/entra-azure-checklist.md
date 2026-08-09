# Entra / Azure configuration checklist (MVP device path)

**Scope:** Admin-console and Azure-side work to support the **same** client Ansible used in lab.  
**Not in scope:** Entra CBA (user passwordless) — Future; see REQ-F\* in [ENTRA_REQUESTS.md](../implementation/ENTRA_REQUESTS.md).

Fill `ltz_microsoft` in `client/ansible/vars/ltz.yml` as you complete items.

---

## A. Tenant & licensing

| # | Task | Portal / product | Done |
|---|------|------------------|------|
| A1 | Confirm tenant ID + primary domain | Entra ID → Overview | ☐ |
| A2 | Pilot security group (e.g. `LTZ-Pilot`) | Entra ID → Groups | ☐ |
| A3 | Pilot user in group; interactive sign-in works | Entra ID → Users | ☐ |
| A4 | Intune license on pilot (group-based licensing preferred) | Entra ID → Licenses / M365 admin | ☐ |
| A5 | MDM authority = Intune | Intune admin center | ☐ |

**Vars:** `ltz_microsoft.tenant_id`, `tenant_domain`, `pilot_group`, `pilot_user_upn`.

---

## B. Linux enrollment

| # | Task | Notes | Done |
|---|------|-------|------|
| B1 | Allow Linux enrollment for pilot | Intune → Devices → Enrollment restrictions | ☐ |
| B2 | Host has Intune stack | `bootstrap-host` / `ltz_intune_prereqs` | ☐ |
| B3 | Enroll pilot workstation | Console: `intune-portal` / Company Portal | ☐ |
| B4 | Device appears in Intune | Devices → Linux | ☐ |

**REQ:** M01, M02 — [entra-access-requests.md](../implementation/entra-access-requests.md).

---

## C. Compliance (attestor-backed)

| # | Task | Artifact / setting | Done |
|---|------|--------------------|------|
| C1 | Built-in Linux compliance baseline (optional) | Encryption, distro allow-list | ☐ |
| C2 | Upload custom discovery script | `client/intune/discovery.sh` | ☐ |
| C3 | Upload custom rules JSON | `client/intune/rules.json` | ☐ |
| C4 | Compliance policy assigned to pilot group | Require custom script success | ☐ |
| C5 | Device reports **Compliant** | Requires fresh attestor ticket on host | ☐ |

**Vars:** `intune_compliance_script`, `intune_compliance_rules`.  
**REQ:** M03, M04.

Discovery only passes when `/var/lib/ltz-trust/status.json` shows attested + fresh ticket — same contract as lab.

---

## D. Conditional Access (after C5 green)

| # | Task | Notes | Done |
|---|------|-------|------|
| D1 | CA policy report-only: require compliant device | Pilot cloud apps | ☐ |
| D2 | Validate sign-in logs | Compliant vs blocked | ☐ |
| D3 | Flip policy to **On** | Break-glass exclusions first | ☐ |
| D4 | Break-glass accounts excluded | REQ-M07 | ☐ |

**Vars:** `ltz_microsoft.conditional_access_require_compliant: true` when On.  
**REQ:** M05, M06, M07.

---

## E. Device PKI / 802.1X (optional for first Intune demo)

| # | Task | Lab equivalent | Done |
|---|------|----------------|------|
| E1 | Device issuing CA available | step-ca intermediate | ☐ |
| E2 | Ticket-gated mint or Cloud PKI enrollment gated by posture | cert-mint | ☐ |
| E3 | Point `ltz_cert_mint_url` at mint | lab :8445 | ☐ |
| E4 | RADIUS trusts device issuing CA | FreeRADIUS ca.pem | ☐ |
| E5 | Host has CA bundle at `ltz_radius_ca_file` | lab-ca-bundle.pem | ☐ |
| E6 | EAP-TLS success for pilot host | eapol_test / NAS | ☐ |

**Vars:** `cloud_pki_enabled`, `cloud_pki_mint_url`, `cloud_pki_issuing_ca_thumbprint`, `ltz_radius_*`.

Cloud PKI product configuration is tenant-specific; keep the **ticket gate** semantics from lab.

---

## F. Azure Attestation / MAA (optional)

| # | Task | Notes | Done |
|---|------|-------|------|
| F1 | Confirm license / MAA resource | Not included in basic E3 Intune | ☐ |
| F2 | Deploy or configure MAA endpoint | Azure portal | ☐ |
| F3 | Attestor host: `LTZ_ATTESTOR_BACKEND=maa` | `services/attestor` | ☐ |
| F4 | Client still only calls attestor URL | No client code change | ☐ |

**Vars:** `maa_enabled`, `maa_endpoint`.

---

## G. Optional Graph automation

| # | Task | Done |
|---|------|------|
| G1 | App registration for collector/inventory (if needed) | ☐ |
| G2 | Least-privilege app roles / Graph permissions | ☐ |
| G3 | Record `graph_app_id` in vars | ☐ |

**REQ:** M08, M09 — only if automation needs Graph.

---

## H. Explicit non-goals (do not block MVP)

| Item | Why deferred |
|------|----------------|
| Entra CBA / Hello-class user certs | User plane; REQ-F\* |
| Autopilot / hybrid join for Linux | Linux Intune enroll is not Windows Autopilot |
| SPIRE / workload federation | Future workload plane |
| Production PIM for CBA admins | Future |

---

## I. Handoff packet (attach to demo)

1. Filled `vars/ltz.yml` (redact secrets) or inventory group_vars  
2. Pilot device name + Intune device ID  
3. Screenshot or export: Compliant = true  
4. Optional: RADIUS accept log or eapol SUCCESS  
5. Link to [lab-trust-proof.md](lab-trust-proof.md) evidence if lab still running  

---

## Quick reference — vars block

```yaml
ltz_microsoft:
  tenant_id: "..."
  tenant_domain: "....onmicrosoft.com"
  pilot_group: "LTZ-Pilot"
  pilot_user_upn: "pilot@...."
  intune_compliance_script: "client/intune/discovery.sh"
  intune_compliance_rules: "client/intune/rules.json"
  conditional_access_require_compliant: false
  cloud_pki_enabled: false
  cloud_pki_mint_url: ""
  cloud_pki_issuing_ca_thumbprint: ""
  maa_enabled: false
  maa_endpoint: ""
  cba_enabled: false
  graph_app_id: ""
```
