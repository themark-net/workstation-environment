# ltz_sssd_oidc

SSSD OIDC → Microsoft Entra user login (user plane).

**Not device trust.** Does not issue 802.1X device certs or replace the attestor.

## Enable

```yaml
ltz_enable_sssd_oidc: true
ltz_sssd_oidc:
  tenant_id: "..."
  domain: "contoso.onmicrosoft.com"
  client_id: "app-registration-guid"
  scope: "openid profile email offline_access"
```

See docs/deployment/sssd-oidc-staging.md.
