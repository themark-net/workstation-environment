# Intune + Linux LTZ client

Canonical operator guide for connecting **ltz-client** to Microsoft Intune.

## Boundaries

```text
Intune custom compliance  →  discovery.sh + rules.json   (report only)
Intune platform script    →  install-ansible-pull.sh     (root, optional)
Ansible bootstrap         →  packages, agent, LUKS, SSSD, modular roles
ansible-pull              →  pull-local.yml              (drift, safe subset)
```

Full step-by-step for portal, test, and prod: **[client/intune/README.md](../../client/intune/README.md)**.

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
| `ltz_enable_compliance` | `ltz_compliance` | Assert posture |
| `ltz_enable_sssd_oidc` | `ltz_sssd_oidc` | User Entra login |
| `ltz_enable_ansible_pull` | `ltz_ansible_pull` | Timer from Ansible |
| `ltz_enable_mdatp` | `ltz_mdatp` | Stub |
| `ltz_enable_nessus` | `ltz_nessus` | Stub |
| `ltz_enable_log_forward` | `ltz_log_forward` | Stub |

New modules: copy `roles/_template`.
