# ltz-client (production client reference tree)

**Standalone production-shaped host components for LTZ device trust.**  
**No dependency on `lab/`.** Lab and Microsoft/demo hosts use the **same** Ansible roles; only `vars/ltz.yml` (and inventory) change.

When ready for production testing, extract this directory to its own Git repository (`ltz-client`).

---

## Transition model

```text
1) Lab (air-gap Proxmox)     → prove trust planes with local attestor / step-ca / FreeRADIUS
2) Docs (lab trust proof)    → docs/deployment/lab-trust-proof.md
3) Same Ansible on real hosts → fill vars/ltz.yml (microsoft-dev) + ship CA bundle
4) Entra/Azure admin work    → docs/deployment/entra-azure-checklist.md
```

See **[docs/deployment/README.md](../docs/deployment/README.md)** for the full path.

---

## Contents

| Path | Purpose |
|------|---------|
| `agent/` | Trust/compliance agent (status + attest orchestration) |
| `attestor-client/` | Notes for calling remote thin attestor |
| `intune/` | Discovery + rules + optional ansible-pull seed (**upload** to Intune) |
| `ansible/` | Bootstrap playbook + roles for any new host |

### Ansible layout

| Path | Purpose |
|------|---------|
| `ansible/vars/ltz.yml.example` | **One vars surface** — endpoints, Microsoft block, modular enables |
| `ansible/vars/ltz-microsoft-dev.yml.example` | Same keys, demo/prod-shaped values |
| `ansible/playbooks/bootstrap-host.yml` | Full first-boot: core + modular roles |
| `ansible/playbooks/pull-local.yml` | Safe subset for ansible-pull (assert + modular) |
| `ansible/playbooks/site.yml` | Alias for bootstrap-host |
| `ansible/roles/ltz_tpm_luks` | TPM + LUKS baseline + recovery escrow |
| `ansible/roles/ltz_intune_prereqs` | Edge, Intune portal, identity broker, GNOME |
| `ansible/roles/ltz_trust_agent` | Attestor client timer + status.json |
| `ansible/roles/ltz_device_cert` | Ticket-gated CSR → mint → EAP-TLS material |
| `ansible/roles/ltz_sssd_oidc` | User-plane SSSD → Entra OIDC |
| `ansible/roles/ltz_compliance` | Assert posture → compliance.json |
| `ansible/roles/ltz_ansible_pull` | systemd timer for ansible-pull |
| `ansible/roles/ltz_mdatp` | Placeholder (Defender for Endpoint) |
| `ansible/roles/ltz_nessus` | Placeholder (Nessus) |
| `ansible/roles/ltz_log_forward` | Placeholder (log shipping) |
| `ansible/roles/_template` | Copy-me for new modular roles |

### Modular role flags (vars/ltz.yml)

| Flag | Role | Default |
|------|------|---------|
| `ltz_enable_compliance` | `ltz_compliance` | true |
| `ltz_enable_sssd_oidc` | `ltz_sssd_oidc` | false |
| `ltz_enable_ansible_pull` | `ltz_ansible_pull` | false |
| `ltz_enable_mdatp` | `ltz_mdatp` | false |
| `ltz_enable_nessus` | `ltz_nessus` | false |
| `ltz_enable_log_forward` | `ltz_log_forward` | false |

New modules: copy `roles/_template`, rename flags, add an entry under `ltz_modular_roles` in `vars/ltz.yml.example`.

---

## Install (lab or real hosts — identical)

```bash
cd client/ansible
cp vars/ltz.yml.example vars/ltz.yml
# Edit URLs / ltz_microsoft block / modular enables.
# For Microsoft demo:
#   cp vars/ltz-microsoft-dev.yml.example vars/ltz.yml

cp inventory/hosts.example.yml inventory/hosts.yml
# Edit hosts and ansible_user

ansible-playbook -i inventory/hosts.yml playbooks/bootstrap-host.yml
```

What bootstrap does on a **new** host:

1. Class / profile markers
2. TPM + LUKS baseline (assert / enroll / data_volume)
3. Optional Intune GUI stack (workstations)
4. Trust agent → attestor → `status.json` + ticket
5. Optional device cert (if `ltz_cert_mint_url` set) for 802.1X
6. Modular roles driven by enable flags (SSSD OIDC, compliance, placeholders, ansible-pull)

**Microsoft-specific admin work is not inventing a second playbook tree** — it is:

- Filling `ltz_microsoft` in `vars/ltz.yml`
- Uploading `intune/*` in the portal (see **[intune/README.md](intune/README.md)**)
- Pointing attestor/mint/RADIUS at in-place components
- Following [docs/deployment/entra-azure-checklist.md](../docs/deployment/entra-azure-checklist.md)

---

## Runtime flow (MVP)

```text
systemd timer → ltz-trust-agent
  → gather local health
  → POST /v1/attest (thin attestor only)
  → store ticket under /var/lib/ltz-trust/
  → POST status to collector (with ticket)
  → write status.json for Intune discovery script

optional:
  ltz-request-device-cert
  → CSR + ticket → cert mint
  → /var/lib/ltz-trust/pki/ for EAP-TLS

optional (modular):
  ltz_compliance → compliance.json
  ltz_sssd_oidc  → /etc/sssd/sssd.conf (user login)
  ltz_ansible_pull → ltz-ansible-pull.timer → pull-local.yml
```

Intune discovery **only passes** if a **non-expired ticket** is present (and disk encryption when required). It does not invent posture without attestor success.

---

## Intune plug-in day

Full operator guide (implementation, testing, prod): **[intune/README.md](intune/README.md)**.

Short version:

1. Enroll device (Company Portal / `intune-portal`).
2. Upload `intune/discovery.sh` as **custom compliance** discovery script.
3. Upload `intune/rules.json`.
4. (Optional) Upload `intune/install-ansible-pull.sh` as a **platform script** (Root, once).
5. Assign compliance policy to pilot group (`ltz_microsoft.pilot_group`).
6. Turn on Conditional Access “require compliant” only after pilot is green.

No host-agent code change if paths match role defaults.

---

## Architecture

- [docs/deployment/README.md](../docs/deployment/README.md) — lab → Microsoft transition  
- [docs/architecture/MVP-AND-FUTURE-STATE.md](../docs/architecture/MVP-AND-FUTURE-STATE.md)  
- [docs/architecture/REPO-BOUNDARIES.md](../docs/architecture/REPO-BOUNDARIES.md)  

### Disk encryption

Role **`ltz_tpm_luks`** is included from `bootstrap-host.yml`. See [docs/runbooks/tpm-luks-disk-encryption.md](../docs/runbooks/tpm-luks-disk-encryption.md).

### SSSD OIDC staging

See [docs/deployment/sssd-oidc-staging.md](../docs/deployment/sssd-oidc-staging.md).
