# Workstation Environment

Architecture design repo for **Linux Zero Trust** on the Microsoft Entra / Intune / Conditional Access plane.

**Current priority:** **MVP device compliance** (thin attestor → Intune-shaped compliance → CA compliant device).  
**SSSD OIDC → Entra** user login is **done**. **Entra CBA** (Hello-class passwordless) is **Future**, not required for MVP.

## Start here

| Doc | Link |
|------|------|
| **Lab → Microsoft transition** | [docs/deployment/README.md](docs/deployment/README.md) |
| MVP vs Future | [docs/architecture/MVP-AND-FUTURE-STATE.md](docs/architecture/MVP-AND-FUTURE-STATE.md) |
| Repo boundaries | [docs/architecture/REPO-BOUNDARIES.md](docs/architecture/REPO-BOUNDARIES.md) |
| Entra / Azure checklist | [docs/deployment/entra-azure-checklist.md](docs/deployment/entra-azure-checklist.md) |
| Entra REQ (MVP/Future) | [docs/implementation/ENTRA_REQUESTS.md](docs/implementation/ENTRA_REQUESTS.md) |
| Production client tree | [client/README.md](client/README.md) |
| Lab MVP deploy | [lab/README.md](lab/README.md) |

## Trees

```text
client/          # ltz-client — prod host agent + Intune artifacts + Ansible (NO lab deps)
                 # ONE vars file: client/ansible/vars/ltz.yml — lab vs microsoft-dev
services/        # ltz-attestor, ltz-collector — prod services (NO lab deps)
lab/             # Proxmox + lab glue only — deploys services/client onto lab VMs
docs/deployment/ # Lab trust proof → Microsoft path → Entra checklist
docs/            # Architecture source of truth
```

## Lab MVP quick path

```bash
cd lab
make tf-apply && make wait-ssh
make ansible-site-full    # bootstrap + mvp dual-path + 802.1X
# or: make ansible-mvp && make ansible-8021x
make validate
```

## Real / Microsoft-dev hosts (same client Ansible)

```bash
cd client/ansible
cp vars/ltz-microsoft-dev.yml.example vars/ltz.yml   # fill tenant + URLs
cp inventory/hosts.example.yml inventory/hosts.yml
ansible-playbook -i inventory/hosts.yml playbooks/bootstrap-host.yml
```

## Base workstation playbook (unrelated baseline)

```bash
ansible-playbook -i inventory.yml setup-workstation.yml --become
```
