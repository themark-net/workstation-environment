# Staging: SSSD OIDC → Entra

**Status:** Host role **`ltz_sssd_oidc`** is in `client/ansible`. Enable with tenant app registration, then validate login.

## Enable on host

```yaml
# vars/ltz.yml
ltz_enable_sssd_oidc: true
ltz_sssd_oidc:
  tenant_id: "YOUR-TENANT-GUID"
  domain: "yourtenant.onmicrosoft.com"
  client_id: "YOUR-APP-CLIENT-ID"
  scope: "openid profile email offline_access"
```

```bash
ansible-playbook -i inventory/hosts.yml playbooks/bootstrap-host.yml
```

## Tenant / Entra artifacts (CARs)

| # | Artifact | Done |
|---|----------|------|
| O1 | App registration for Linux OIDC (SSSD) | ☐ |
| O2 | Client ID + tenant ID in vars | ☐ |
| O3 | API permissions (openid, profile, email, offline_access) | ☐ |
| O4 | Admin consent | ☐ |
| O5 | Pilot users in pilot group | ☐ |
| O6 | CA for user sign-in (after device compliance green) | ☐ |

## Host checks

| # | Task | Done |
|---|------|------|
| H1 | Role packages installed (`sssd`, `sssd-idp`) | ☐ |
| H2 | `/etc/sssd/sssd.conf` deployed | ☐ |
| H3 | NTP OK | ☐ |
| H4 | `id pilot@tenant` / `sssctl domain-status` | ☐ |
| H5 | Interactive login | ☐ |
| H6 | Device agent still attested | ☐ |

## Non-goals

- Entra CBA (Future)
- User OIDC for machine 802.1X
- Replacing attestor with "user logged in"

## Related

- [client/ansible/roles/ltz_sssd_oidc/README.md](../../client/ansible/roles/ltz_sssd_oidc/README.md)
- [intune-linux.md](intune-linux.md)
- [entra-azure-checklist.md](entra-azure-checklist.md)
