# Repositories & Dependencies

**Last updated:** 2026-08-07  
**Canonical detail:** [../architecture/REPO-BOUNDARIES.md](../architecture/REPO-BOUNDARIES.md)

| Logical name | Purpose | Status | Prod dependency on lab? |
|--------------|---------|--------|-------------------------|
| **goldimage** | SSH, YubiKey admin baselines | Exists | No |
| **sssd-hybrid** | OIDC + hybrid UID/GID | Done | No |
| **workstation-environment** | Architecture, imports, lab harness docs | This repo | N/A |
| **ltz-client** (`client/`) | Host agent, Intune artifacts, Ansible | MVP build | **No** |
| **ltz-attestor** (`services/attestor/`) | Thin attestor | MVP build | **No** |
| **ltz-collector** (`services/collector/`) | Report sink / mock Intune | MVP build | **No** |
| **ltz-lab** (`lab/`) | Proxmox + lab-only deploy | Lab only | N/A |
| **zt-awx-config** | AWX CasC | Future | No |
| **zt-spire-config** | SPIRE | Future | No |

## Versioning

- Pin **ltz-client** / attestor / collector tags in lab and AWX.  
- Never pin production automation to `lab/` paths.  
- Docs: `main` on this repo is architecture source of truth.

### 802.1X / RADIUS

| Dependency | Owner |
|------------|--------|
| Device client cert from attestor/CA | ltz-attestor + PKI |
| Client EAP-TLS config | ltz-client Ansible |
| Lab RADIUS | ltz-lab |
| Production RADIUS/NPS + switch/WLAN | Network team (external) |
