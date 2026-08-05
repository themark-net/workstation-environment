# Repositories & Dependencies

| Logical name | Purpose | Status |
|--------------|---------|--------|
| **goldimage** | SSH, YubiKey admin, common baseline playbooks | Exists — consume by tag |
| **sssd-hybrid / customized SSSD** | Hybrid UID/GID + OIDC | Done — out of scope for new work |
| **workstation-environment** | Architecture, runbooks, Jira/GitLab import | This repo |
| **ansible-workstation-environment** | ZT policy packs / roles | Expand |
| **awx-config** | AWX CasC / job templates / inventories | Create |
| **spire-infra** | SPIRE server/agent, policies | Create |
| **trust-agent** | status.json generator | Create (or role inside ansible repo) |

## Versioning

- goldimage: pin `vX.Y.Z` in AWX project.
- SPIRE: pin release versions; upgrade via change window.
- Docs: this repo `main` is source of truth for architecture.

## GitLab ↔ Jira

See [docs/project/README.md](../project/README.md).
