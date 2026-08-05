# Workstation Environment

Architecture, runbooks, and **agile delivery packs** for Linux workstations on the shared **Microsoft Entra / Intune / Conditional Access** Zero Trust plane—plus **AWX** continuous configuration, **MS CA workload certificates**, and **SPIRE** for non-human identity.

## Documentation map

| Path | What |
|------|------|
| [docs/executive/EXECUTIVE-PROPOSAL.md](docs/executive/EXECUTIVE-PROPOSAL.md) | Leadership proposal + ask |
| [docs/executive/COST-ESTIMATES.md](docs/executive/COST-ESTIMATES.md) | ~952 person-hours breakdown |
| [docs/implementation/IMPLEMENTATION-PLAN.md](docs/implementation/IMPLEMENTATION-PLAN.md) | Phased delivery plan |
| [docs/implementation/entra-access-requests.md](docs/implementation/entra-access-requests.md) | Entra/Intune/PKI request templates |
| [docs/project/](docs/project/) | **Jira CSV + GitLab CSV imports** |
| [docs/architecture/](docs/architecture/) | Planes, SPIRE, workload PKI |
| [docs/runbooks/](docs/runbooks/) | Operational ZT runbooks |

## Hard requirements

- **No USB** for day-to-day Entra passwordless → **TPM + Entra CBA**
- User SSSD OIDC hybrid: **done** (out of band)
- **Goldimage** Ansible: SSH + YubiKey admin baselines (consume by tag)
- New **AWX OSS** + **SPIRE** in scope for management/workload planes

## Base playbook (lab)

```bash
ansible-playbook -i inventory.yml setup-workstation.yml --become
```

Enterprise ZT delivery is documented under **docs/**—not only this sample playbook.

## Project import (PMO)

1. Read [docs/project/README.md](docs/project/README.md)
2. Import [docs/project/jira/jira-issues.csv](docs/project/jira/jira-issues.csv)
3. Import [docs/project/gitlab/gitlab-issues.csv](docs/project/gitlab/gitlab-issues.csv)
4. Fill [docs/project/mapping/jira-gitlab-crosswalk.csv](docs/project/mapping/jira-gitlab-crosswalk.csv)

## License / use

Internal architecture and delivery artifacts for the LZT-WWI program.
