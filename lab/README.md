# LTZ Lab Environment (lab-only)

**This tree provisions disposable lab infrastructure only.**  
It is **not** a production dependency. Production client code lives in [`../client/`](../client/); services in [`../services/`](../services/).

See [docs/architecture/REPO-BOUNDARIES.md](../docs/architecture/REPO-BOUNDARIES.md).

## MVP path (compliance-first + device 802.1X)

```bash
cd lab
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# edit tfvars

make tf-init && make tf-apply
make wait-ssh
make ansible-bootstrap
make ansible-mvp          # attestor + collector + RADIUS + enroll + client roles
make validate
```

`ansible-mvp` deploys:

1. **Thin attestor** (`services/attestor`) on `lab_rp` with **device CA** (issues short-lived client certs)  
2. **Collector** + mock Intune sink (`services/collector`) on `lab_rp`  
3. **FreeRADIUS** (`lab_radius`) on `lab_rp` trusting the device CA  
4. **Enroll** workstation birth record  
5. **Production client roles** (`ltz_trust_agent`, `ltz_8021x`) on `lab_workstations`  

No CBA, no SPIRE in MVP.

## Layout

| Path | Role |
|------|------|
| `terraform/` | Proxmox VMs (incl. vTPM workstation) |
| `ansible/roles/lab_*` | Lab-only glue (incl. `lab_radius`) |
| `ansible/playbooks/mvp.yml` | MVP orchestration |
| `../client/` | **Prod client** (referenced, not forked) |
| `../services/` | **Prod services** (copied onto lab VMs at deploy time) |

## Full legacy site playbook

`make ansible-lab` still runs broader POC roles. Prefer **`make ansible-mvp`** for the compliance-first + 802.1X demo.
