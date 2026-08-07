# Workstation Environment

Architecture design repo for **Linux Zero Trust** on the Microsoft Entra / Intune / Conditional Access plane.

**Current priority:** **MVP device compliance** (thin attestor → Intune-shaped compliance → CA compliant device).  
**SSSD OIDC → Entra** user login is **done**. **Entra CBA** (Hello-class passwordless) is **Future**, not required for MVP.

## Start here

| Doc | Link |
|------|------|
| MVP vs Future | [docs/architecture/MVP-AND-FUTURE-STATE.md](docs/architecture/MVP-AND-FUTURE-STATE.md) |
| Repo boundaries | [docs/architecture/REPO-BOUNDARIES.md](docs/architecture/REPO-BOUNDARIES.md) |
| Entra REQ (MVP/Future) | [docs/implementation/ENTRA_REQUESTS.md](docs/implementation/ENTRA_REQUESTS.md) |
| Production client tree | [client/README.md](client/README.md) |
| Lab MVP deploy | [lab/README.md](lab/README.md) |

## Trees

```text
client/          # ltz-client — prod host agent + Intune artifacts + Ansible (NO lab deps)
services/        # ltz-attestor, ltz-collector — prod services (NO lab deps)
lab/             # Proxmox + lab glue only — deploys services/client onto lab VMs
docs/            # Architecture source of truth
```

## Lab MVP quick path

```bash
cd lab
make tf-apply && make wait-ssh && make ansible-mvp && make validate
```

## Base workstation playbook (unrelated baseline)

```bash
ansible-playbook -i inventory.yml setup-workstation.yml --become
```
