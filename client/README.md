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
| `intune/` | Discovery script + rules JSON (**upload** to Intune admin) |
| `ansible/` | Bootstrap playbook + roles for any new host |

### Ansible layout

| Path | Purpose |
|------|---------|
| `ansible/vars/ltz.yml.example` | **One vars surface** — endpoints + Microsoft tenant block |
| `ansible/vars/ltz-microsoft-dev.yml.example` | Same keys, demo/prod-shaped values |
| `ansible/playbooks/bootstrap-host.yml` | Pre-reqs + agent + optional device cert |
| `ansible/playbooks/site.yml` | Alias for bootstrap-host |
| `ansible/roles/ltz_intune_prereqs` | Edge, Intune portal, identity broker, GNOME |
| `ansible/roles/ltz_trust_agent` | Attestor client timer + status.json |
| `ansible/roles/ltz_device_cert` | Ticket-gated CSR → mint → EAP-TLS material |

---

## Install (lab or real hosts — identical)

```bash
cd client/ansible
cp vars/ltz.yml.example vars/ltz.yml
# Edit URLs / ltz_microsoft block. For Microsoft demo:
#   cp vars/ltz-microsoft-dev.yml.example vars/ltz.yml

cp inventory/hosts.example.yml inventory/hosts.yml
# Edit hosts and ansible_user

ansible-playbook -i inventory/hosts.yml playbooks/bootstrap-host.yml
```

What bootstrap does on a **new** host:

1. Class marker (`workstation` | `server`)
2. Optional Intune GUI stack (workstations)
3. Trust agent → attestor → `status.json` + ticket
4. Optional device cert (if `ltz_cert_mint_url` set) for 802.1X

**Microsoft-specific admin work is not inventing a second playbook tree** — it is:

- Filling `ltz_microsoft` in `vars/ltz.yml`
- Uploading `intune/*` in the portal
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
```

Intune discovery **only passes** if a **non-expired ticket** is present. It does not invent posture without attestor success.

---

## Intune plug-in day

1. Enroll device (Company Portal / `intune-portal`).  
2. Upload `intune/discovery.sh` as custom compliance discovery script.  
3. Upload `intune/rules.json`.  
4. Assign compliance policy to pilot group (`ltz_microsoft.pilot_group`).  

No host-agent code change if paths match role defaults.

---

## Architecture

- [docs/deployment/README.md](../docs/deployment/README.md) — lab → Microsoft transition  
- [docs/architecture/MVP-AND-FUTURE-STATE.md](../docs/architecture/MVP-AND-FUTURE-STATE.md)  
- [docs/architecture/REPO-BOUNDARIES.md](../docs/architecture/REPO-BOUNDARIES.md)  
