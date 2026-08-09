# Microsoft / real-host path (same Ansible)

After [lab-trust-proof.md](lab-trust-proof.md) is green, deploy **the same client roles** against developer or production-shaped hosts. Lab code stays behind; only endpoints and Entra-side configuration change.

---

## 1. Principle

| Keep identical | Swap via vars / inventory |
|----------------|---------------------------|
| `playbooks/bootstrap-host.yml` | Host list, SSH user |
| Roles `ltz_intune_prereqs`, `ltz_trust_agent`, `ltz_device_cert` | `ltz_attestor_url`, mint, RADIUS |
| `client/intune/discovery.sh` + `rules.json` | Tenant where you upload them |
| Ticket → status.json contract | Attestor backend `local` vs `maa` (**server-side**) |

Do **not** fork a “microsoft-ansible” tree.

---

## 2. Prerequisites on the Microsoft side

Minimum for a **demo** (E3-class is enough for Intune Linux + CA; E5/MAA optional):

1. Tenant with Intune + Entra ID P1 (or trial)  
2. Pilot security group + licensed pilot user  
3. Linux enrollment allowed  
4. Place to run thin attestor + collector (Azure VM, lab RP still reachable, or on-prem)  
5. Optional later: Cloud PKI, MAA, corp RADIUS  

Admin steps: [entra-azure-checklist.md](entra-azure-checklist.md) and [../implementation/ENTRA_REQUESTS.md](../implementation/ENTRA_REQUESTS.md).

---

## 3. Host bootstrap (real or microsoft-dev)

```bash
cd client/ansible
cp vars/ltz-microsoft-dev.yml.example vars/ltz.yml
# Set:
#   ltz_attestor_url / ltz_collector_url
#   ltz_cert_mint_url (if 802.1X in scope)
#   ltz_microsoft.tenant_* , pilot_group, pilot_user_upn
#   flags: cloud_pki_enabled, maa_enabled, conditional_access_require_compliant

cp inventory/hosts.example.yml inventory/hosts.yml
# Workstations: ltz_host_class=workstation, strict_tpm=true
# Servers:      ltz_host_class=server, install_intune=false, strict_tpm as hardware allows

ansible-playbook -i inventory/hosts.yml playbooks/bootstrap-host.yml
```

### What you must install outside this playbook

| Component | Notes |
|-----------|--------|
| Attestor service | `services/attestor` — set `LTZ_ATTESTOR_BACKEND=local` or `maa` |
| Collector (optional) | `services/collector` |
| Device cert mint | Lab cert-mint shape **or** Cloud PKI-backed signer that still checks tickets |
| RADIUS | Trust **device issuing CA**; secret + host in `ltz_radius_*` |
| CA bundle on host | Enterprise intermediate+root at `ltz_radius_ca_file` (default `/etc/ltz-trust/lab-ca-bundle.pem`) |

The bootstrap playbook assumes mint/RADIUS already exist when `ltz_enable_device_cert: true`. For **Intune-only** first pass, set `ltz_enable_device_cert: false` until mint is ready.

---

## 4. Mapping lab URLs → real services

| Lab (`ltz.yml` lab profile) | Real / microsoft-dev |
|-----------------------------|----------------------|
| `http://10.42.0.146:8443` attestor | `https://attestor.<your-domain>` |
| `http://10.42.0.146:8089` collector | Your collector or disable |
| `http://10.42.0.57:8445` cert mint | Cloud PKI front door or cert-mint VM |
| FreeRADIUS on RP | NPS / FreeRADIUS / cloud RADIUS |
| `lab-join` token | Vaulted join token |
| HMAC secret on attestor | Rotate; or switch backend to MAA |

---

## 5. MAA (optional, attestor host only)

Clients **never** call MAA. On the attestor host:

```bash
export LTZ_ATTESTOR_BACKEND=maa
export LTZ_MAA_ENDPOINT=https://<your-maa-instance>   # if required by backend
# deploy services/attestor with those env vars
```

In `vars/ltz.yml`:

```yaml
ltz_microsoft:
  maa_enabled: true
  maa_endpoint: "https://..."
```

License note: MAA is not implied by E3 Intune alone. Lab remains valid with `local` backend.

---

## 6. Cloud PKI vs lab step-ca

| Concern | Lab | Microsoft path |
|---------|-----|----------------|
| Issuer | step-ca intermediate | Cloud PKI / enterprise intermediate |
| Gate | cert-mint + attestor ticket | **Keep the gate** — do not open enrollment |
| Client role | `ltz_device_cert` | Same; change `ltz_cert_mint_url` |
| RADIUS trust | lab-ca-bundle.pem | Enterprise chain file at same path |

Cloud PKI is **not** MAA and **not** user CBA.

---

## 7. Intune presentation (workstations)

1. Bootstrap installs Edge + intune-portal (+ GNOME if enabled).  
2. Human: sign in as pilot UPN → enroll.  
3. Admin: upload `client/intune/discovery.sh` + `rules.json` as custom compliance.  
4. Assign policy to `ltz_microsoft.pilot_group`.  
5. Confirm device **Compliant** when `status.json` has fresh ticket.  
6. Only then consider CA “require compliant device” (report-only → on).

---

## 8. Server path (no MDM)

Same `bootstrap-host.yml` with:

```yaml
ltz_host_class: server
ltz_install_intune_prereqs: false
ltz_intune_install_desktop: false
ltz_strict_tpm: false   # or true if vTPM/hardware present
ltz_enable_device_cert: true
```

Proves ticket + optional 802.1X without Intune. Matches lab `lab_servers`.

---

## 9. Definition of done (microsoft-dev demo)

- [ ] `bootstrap-host` green on pilot workstation + one server  
- [ ] `status.json` attested with non-expired ticket  
- [ ] Intune shows Compliant for pilot (custom rules)  
- [ ] If 802.1X in scope: device cert issued; RADIUS accept (or eapol against test NAS)  
- [ ] `ltz_microsoft` block fully filled for the tenant used  
- [ ] Entra checklist items for MVP marked done  

---

## 10. Still missing / not automated (honest gaps)

These require **tenant admin or network engineering**, not more host Ansible:

1. Creating the Entra tenant policies (compliance, CA) — checklist only  
2. Issuing Cloud PKI templates / SCEP profiles if you abandon cert-mint API  
3. Physical NAS/switch RADIUS client config  
4. MAA resource provisioning and attestor AAD app (if any)  
5. Break-glass and production CA change control  

Host pre-reqs and the trust **protocol** are what this repo automates end-to-end.
