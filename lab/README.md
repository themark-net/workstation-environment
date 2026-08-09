# LTZ Lab Environment (lab-only)

**This tree provisions disposable lab infrastructure only.**  
It is **not** a production dependency. Production client code lives in [`../client/`](../client/); services in [`../services/`](../services/).

See [docs/architecture/REPO-BOUNDARIES.md](../docs/architecture/REPO-BOUNDARIES.md).

## MVP path (compliance-first) — dual device classes

```bash
cd lab
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# edit tfvars

make tf-init && make tf-apply
make wait-ssh
make ansible-site-full    # bootstrap + mvp + 802.1X (one shot)
# or stepwise:
#   make ansible-bootstrap && make ansible-mvp && make ansible-8021x
make demo-paths           # show workstation vs server status.json
make validate
```

**Transition to real/Microsoft hosts:** same client roles via `../client/ansible` + one vars file.  
See [docs/deployment/README.md](../docs/deployment/README.md).

`ansible-mvp` deploys:

| Path | Inventory | What gets installed | Demo |
|------|-----------|---------------------|------|
| **A — Workstation** | `lab_workstations` (`ltz-lab-ws1`) | GNOME + Edge + Intune portal + trust agent + attestor enroll | Console → `intune-portal` → pilot user; custom compliance reads `status.json` |
| **B — Server** | `lab_servers` (`ltz-lab-svc-a/b`) | Trust agent + attestor enroll only (no desktop/Intune) | Headless ticket proof; same agent protocol |
| **Control plane** | `lab_rp` | Thin attestor + collector | Tickets + mock compliance sink |

Shared truth: **thin attestor** issues short-lived tickets; agent writes `/var/lib/ltz-trust/status.json`.  
Intune is **optional presentation** for workstations only — servers prove the same attestation model without MDM.

### 802.1X (EAP-TLS) lab extension

```bash
make ansible-mvp
make ansible-8021x
```

Trust split:

| Credential | Consumer | Role |
|------------|----------|------|
| Attestor **ticket** | cert-mint, collector, Intune discovery | Posture OK *now* |
| Device **client cert** (lab step-ca) | FreeRADIUS EAP-TLS | Host identity on the wire |
| Lab CA root/intermediate | RADIUS + clients | X.509 path only |

Attestor is **not** “in the X.509 chain.” It **authorizes minting** of the device cert. RADIUS never sees the HMAC ticket.

No CBA, no SPIRE in MVP.

## Layout

| Path | Role |
|------|------|
| `terraform/` | Proxmox VMs (incl. vTPM workstation) |
| `ansible/roles/lab_*` | Lab-only glue |
| `ansible/playbooks/mvp.yml` | MVP orchestration |
| `../client/` | **Prod client** (referenced, not forked) |
| `../services/` | **Prod services** (copied onto lab VMs at deploy time) |

## Full legacy site playbook

`make ansible-lab` still runs broader POC roles. Prefer **`make ansible-mvp`** for the compliance-first demo.
