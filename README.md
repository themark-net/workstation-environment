# Workstation Environment

Architecture design repo for **Linux Zero Trust** on the Microsoft Entra / Intune / Conditional Access plane.

**Current priority:** **MVP device compliance** (thin attestor → Intune-shaped compliance → CA compliant device) **plus machine 802.1X EAP-TLS** on the same attestor-gated device cert.  
**SSSD OIDC → Entra** user login is **done**. **Entra CBA** (Hello-class passwordless) is **Future**, not required for MVP.

## Start here

| Doc | Link |
|------|------|
| MVP vs Future | [docs/architecture/MVP-AND-FUTURE-STATE.md](docs/architecture/MVP-AND-FUTURE-STATE.md) |
| Device 802.1X (MVP) | [docs/architecture/device-8021x-eap-tls.md](docs/architecture/device-8021x-eap-tls.md) |
| Repo boundaries | [docs/architecture/REPO-BOUNDARIES.md](docs/architecture/REPO-BOUNDARIES.md) |
| Entra REQ (MVP/Future) | [docs/implementation/ENTRA_REQUESTS.md](docs/implementation/ENTRA_REQUESTS.md) |
| Production client tree | [client/README.md](client/README.md) |
| Lab MVP deploy | [lab/README.md](lab/README.md) |

## Trees

```text
client/          # ltz-client — prod host agent + Intune artifacts + Ansible incl. 802.1X (NO lab deps)
services/        # ltz-attestor, ltz-collector — prod services (NO lab deps)
lab/             # Proxmox + lab glue only — FreeRADIUS + deploys services/client onto lab VMs
docs/            # Architecture source of truth
```

## Lab MVP quick path

```bash
cd lab
make tf-apply && make wait-ssh && make ansible-mvp && make validate
```

`ansible-mvp` includes attestor (device certs), collector, enroll, trust agent, **FreeRADIUS**, and **802.1X client config**.

## Base workstation playbook (unrelated baseline)

```bash
ansible-playbook -i inventory.yml setup-workstation.yml --become
```
