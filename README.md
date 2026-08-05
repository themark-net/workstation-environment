# Workstation Environment

Ansible-oriented workspace for uniform Linux workstations on the **Microsoft Entra / Intune / Conditional Access** Zero Trust plane, plus architecture and **Jira/GitLab delivery imports** for the Linux Zero Trust (LTZ) program.

## Quick links

| Area | Link |
|------|------|
| **Docs index** | [docs/README.md](docs/README.md) |
| **Executive proposal** | [docs/implementation/EXECUTIVE_PROPOSAL.md](docs/implementation/EXECUTIVE_PROPOSAL.md) |
| **Implementation plan** | [docs/implementation/IMPLEMENTATION_PLAN.md](docs/implementation/IMPLEMENTATION_PLAN.md) |
| **Man-hour estimates** | [docs/implementation/COST_ESTIMATES.md](docs/implementation/COST_ESTIMATES.md) |
| **Entra IAM request catalog** | [docs/implementation/ENTRA_REQUESTS.md](docs/implementation/ENTRA_REQUESTS.md) |
| **Jira / GitLab imports** | [imports/README.md](imports/README.md) |

## Supported (base playbook)

- RHEL-based: Rocky, Alma, RHEL  
- Debian-based: Ubuntu, Debian, Mint, Pop!_OS, Zorin  

## Program assumptions

- **SSSD OIDC** (user-facing) and **hybrid UID/GID** (custom SSSD + AD hybrid accounts) are **done**.  
- **goldimage** playbooks exist for SSH + YubiKey **admin** baselines.  
- Deploy a **new AWX** (OSS) for Zero Trust policy packs.  
- **SPIRE** is Phase 2+ (workload), not a substitute for Entra CBA.  
- **No USB** for daily Entra passwordless — **TPM + Entra CBA**.  
- Entra changes require formal requests ([ENTRA_REQUESTS.md](docs/implementation/ENTRA_REQUESTS.md)).

## Base playbook usage

```bash
ansible-playbook -i inventory.yml setup-workstation.yml --become
```

Enterprise delivery uses AWX + goldimage + zt-awx-config (see implementation plan).

## Planning total

Approximately **1,300 man-hours** + **15% contingency ≈ 1,495 h** (~9 FTE-months). See cost document for phase gates.
