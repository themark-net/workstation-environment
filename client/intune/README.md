# Intune Linux integration (ltz-client)

Clear separation of concerns for Microsoft Intune on Linux hosts.

```text
┌─────────────────────────────────────────────────────────────────┐
│  Ansible (bootstrap-host / pull-local)                          │
│  • packages, trust agent, LUKS, SSSD, modular roles             │
│  • writes status.json, disk-encryption.json, compliance.json    │
└──────────────────────────────┬──────────────────────────────────┘
                               │
         ┌─────────────────────┴─────────────────────┐
         ▼                                           ▼
┌─────────────────────────┐               ┌─────────────────────────┐
│ Custom compliance       │               │ Platform script (root)  │
│ discovery.sh + rules.json│               │ install-ansible-pull.sh │
│ READ-ONLY report        │               │ seeds systemd timer     │
│ → Compliant / Not       │               │ (optional drift fix)    │
└─────────────────────────┘               └─────────────────────────┘
```

**Never** upload `install-ansible-pull.sh` as a compliance discovery script.
**Never** put mutating logic in `discovery.sh`.

---

## 1. Implementation (portal setup)

### A. Custom compliance (required for CA “require compliant device”)

1. Intune admin center → **Devices** → **Compliance policies** → **Policies** → **Create policy** → **Linux**.
2. Settings:
   - **Custom compliance** → upload:
     - Discovery script: `discovery.sh` (this directory)
     - Detection rules: `rules.json` (this directory)
3. Assign to pilot group (e.g. `LTZ-Pilot` from `ltz_microsoft.pilot_group`).
4. Do **not** enable Conditional Access “require compliant” until pilot devices show **Compliant**.

### B. Platform script — ansible-pull seed (optional)

Use only if you want Intune to plant the pull timer on already-enrolled hosts (GitOps drift remediation without AWX).

1. **Devices** → **Scripts and remediations** → **Platform scripts** → **Add** → **Linux**.
2. Upload `install-ansible-pull.sh`.
3. **Execution context: Root**.
4. Frequency: **Once** (or weekly if you want re-seed).
5. Assign to the same pilot group.

Override defaults (optional) by setting environment on the host before the script runs, or edit the script constants:

| Env / constant       | Default |
|----------------------|---------|
| `LTZ_PULL_REPO_URL`  | this GitHub repo |
| `LTZ_PULL_BRANCH`    | `main` |
| `LTZ_PULL_WORKDIR`   | `/var/lib/ltz-pull` |
| `LTZ_PULL_PLAYBOOK`  | `client/ansible/playbooks/pull-local.yml` |

After first successful run the host owns schedule via `ltz-ansible-pull.timer`.

### C. Ansible side (required regardless of Intune scripts)

```bash
cd client/ansible
cp vars/ltz.yml.example vars/ltz.yml
# fill attestor URLs, enable modular flags as needed
ansible-playbook -i inventory/hosts.yml playbooks/bootstrap-host.yml
```

Or seed pull only via the platform script above; the timer will then run `pull-local.yml` (assert + modular roles, no destructive LUKS/cert mint).

---

## 2. Testing

### On the host (before Intune cares)

```bash
# Trust agent + ticket
cat /var/lib/ltz-trust/status.json | jq .
# Expect: attested=true, ticket_expires_at in the future

# Disk encryption posture (written by ltz_tpm_luks)
cat /var/lib/ltz-trust/disk-encryption.json | jq .

# Optional compliance report (ltz_compliance role)
cat /var/lib/ltz-trust/compliance.json | jq .

# Discovery script as Intune would run it
sudo bash client/intune/discovery.sh | jq .
# Expect: attested=true, ticket_fresh=true, disk_encrypted=true
```

### ansible-pull timer (if seeded)

```bash
systemctl status ltz-ansible-pull.timer
journalctl -u ltz-ansible-pull.service -n 50
cat /var/lib/ltz-trust/ansible-pull-status.json
```

### Intune console

1. Device appears under **Devices** → **All devices** after Company Portal enrollment.
2. Compliance policy evaluates; device moves to **Compliant** when discovery returns the required booleans.
3. Only then consider Conditional Access “require compliant device”.

---

## 3. Future / production deployment

| Stage | Action |
|-------|--------|
| Lab | `ltz_deployment_profile: lab`, local attestor, FreeRADIUS |
| microsoft-dev | Copy `vars/ltz-microsoft-dev.yml.example` → `ltz.yml`; real tenant IDs; Cloud PKI mint URL if used |
| Pilot | 5–20 hosts; compliance policy assigned; CA still **off** |
| Prod | Enable CA require-compliant; set `ltz_compliance_strict: true` on bootstrap if desired; turn on modular roles (MDATP, log forward, etc.) as they are implemented |
| Drift | Prefer ansible-pull timer (seeded by platform script or by `ltz_enable_ansible_pull: true` in bootstrap) over one-shot Intune scripts |

**Prod rules of thumb**

- Keep `discovery.sh` pure (read status files only).
- Prefer Ansible (or pull) for any package/config change.
- Secrets stay in vault / host env / Intune secret store — never in git.
- New compliance claims: extend `discovery.sh` + `rules.json` + (optionally) `ltz_compliance` role together.

---

## File map

| File | Role |
|------|------|
| `discovery.sh` | Custom compliance discovery (read-only) |
| `rules.json` | Custom compliance rules (attested, ticket_fresh, disk_encrypted) |
| `install-ansible-pull.sh` | Platform script — root, seeds systemd timer |
| `../ansible/playbooks/pull-local.yml` | Safe playbook the timer runs |
| `../ansible/roles/ltz_ansible_pull` | Same seed, driven by Ansible enable flag |

Related:

- [docs/deployment/intune-linux.md](../../docs/deployment/intune-linux.md)
- [docs/deployment/sssd-oidc-staging.md](../../docs/deployment/sssd-oidc-staging.md)
- [docs/deployment/entra-azure-checklist.md](../../docs/deployment/entra-azure-checklist.md)
