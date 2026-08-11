# Role template (copy-me)

1. `cp -a roles/_template roles/ltz_<name>`
2. Rename `ltz_enable_TEMPLATE` → `ltz_enable_<name>` in defaults + tasks
3. Add entry under `ltz_modular_roles` in `vars/ltz.yml.example`
4. Implement tasks (idempotent; safe for ansible-pull)
5. Document enable flag + secrets in role README

**Rules:** no secrets in git; prefer assert/install over destructive change; write a status marker under `/var/lib/ltz-trust/` when useful for compliance.
