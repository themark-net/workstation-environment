# Intune + Linux LTZ client

Canonical short reference. Full operator guide (implement / test / prod):

**→ [client/intune/README.md](../../client/intune/README.md)**

## Boundaries

```text
Intune custom compliance  →  discovery.sh + rules.json   (report only)
Intune platform script    →  install-ansible-pull.sh     (root, optional)
Ansible bootstrap         →  packages, agent, LUKS, SSSD, modular roles
ansible-pull              →  pull-local.yml              (drift, safe subset)
```

## Compliance claims (MVP)

| Setting | Source |
|---------|--------|
| `attested` | `/var/lib/ltz-trust/status.json` |
| `ticket_fresh` | ticket not expired |
| `disk_encrypted` | `/var/lib/ltz-trust/disk-encryption.json` |

Host Ansible may also write `compliance.json` via `ltz_compliance`.

## Modular roles

| Flag | Role | Notes |
|------|------|-------|
| `ltz_enable_compliance` | `ltz_compliance` | Assert posture → compliance.json |
| `ltz_enable_sssd_oidc` | `ltz_sssd_oidc` | User Entra login (OIDC) |
| `ltz_enable_ansible_pull` | `ltz_ansible_pull` | Timer (or seed via Intune platform script) |
| `ltz_enable_mdatp` | `ltz_mdatp` | Stub |
| `ltz_enable_nessus` | `ltz_nessus` | Stub |
| `ltz_enable_log_forward` | `ltz_log_forward` | Stub |

New modules: copy `client/ansible/roles/_template`, add flag + `ltz_modular_roles` entry in `vars/ltz.yml.example`.

## Related

- [sssd-oidc-staging.md](sssd-oidc-staging.md)
- [entra-azure-checklist.md](entra-azure-checklist.md)
- [microsoft-path.md](microsoft-path.md)
