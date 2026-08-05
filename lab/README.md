# LTZ Lab Environment

Programmatic deployment of the **offline / pre-tenant POC** lab described in [docs/poc/POC_PATH.md](../docs/poc/POC_PATH.md).

## Why Proxmox

| Option | Pros | Cons | Use when |
|--------|------|------|----------|
| **Proxmox VE** (default) | vTPM easy, full VMs, snapshots, homelab-friendly | Needs a Proxmox host | You already run PVE or can spare a box |
| **libvirt / KVM** | Similar to PVE without PVE UI | More DIY networking | No Proxmox |
| **Docker Compose** (subset) | Fast CA + RP + fake workloads | **No real TPM path** | Crypto-less dry-run of CA/RP only |

**Recommendation:** Proxmox for full POC (vTPM). Use Docker only to smoke-test step-ca + nginx before VMs exist.

## Architecture (default topology)

| VM name | vCPU | RAM | Disk | vTPM | Role |
|---------|-----:|----:|-----:|:----:|------|
| ltz-lab-ca | 2 | 2G | 20G | no | step-ca (lab PKI) |
| ltz-lab-rp | 2 | 2G | 20G | no | nginx mTLS + gate API |
| ltz-lab-ws1 | 4 | 4G | 40G | **yes** | Workstation POC |
| ltz-lab-svc-a | 1 | 1G | 10G | no | Workload A |
| ltz-lab-svc-b | 1 | 1G | 10G | no | Workload B |
| ltz-lab-spire | 2 | 2G | 20G | no | SPIRE server (optional) |

## Prerequisites

### Proxmox host

- Proxmox VE 8.x recommended
- API token with VM provision rights
- Ubuntu 24.04 cloud image template (see `scripts/pve-create-ubuntu-template.sh`)
- swtpm for vTPM (included with PVE TPM emulation)

### Controller

- OpenTofu >= 1.6 or Terraform >= 1.5
- Ansible >= 2.15
- make, ssh, jq

## Quick start

```bash
cd lab
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# edit tfvars

make tf-init
make tf-apply
make wait-ssh
make ansible-bootstrap
make ansible-lab
make validate
```

Optional SPIRE: `make ansible-spire`  
Docker smoke (no TPM): `make docker-up`

## Layout

- `terraform/` — VM lifecycle
- `ansible/` — step-ca, nginx, trust-agent, workloads, spire
- `cloud-init/` — user-data template
- `docker/` — CA+RP subset
- `scripts/` — helpers
- `evidence/` — local validation outputs (gitignored content)
