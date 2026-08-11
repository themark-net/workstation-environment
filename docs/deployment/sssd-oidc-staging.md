# Staging: SSSD OIDC → Entra (next test pass)

**Status:** User plane is designed as **done**; **re-validate against the real/dev tenant** before calling prod MVP complete.  
**Depends on:** App registration + Conditional Access awareness (user sign-in is **not** device compliance).

Lab dual-path + 802.1X may already be green without this step. **OIDC still needs a tenant-side staging pass.**

---

## 1. Goal

Prove a pilot Linux host can:

1. Obtain tokens via **SSSD OIDC** against Entra.  
2. Map user to local/hybrid UID/GID as designed.  
3. Sign in interactively (console/SSH) with MFA per org policy.  
4. Coexist with device trust (attestor/Intune) without using **user** certs for 802.1X.

---

## 2. Tenant / Entra artifacts (CARs / admin asks)

| # | Artifact | Notes | Done |
|---|----------|-------|------|
| O1 | App registration for Linux OIDC (SSSD) | Web/SPA redirect URIs per SSSD docs; **no** public client secrets on hosts if avoidable | ☐ |
| O2 | Client ID + tenant ID in SSSD domain config | From Entra app overview | ☐ |
| O3 | API permissions | OpenID, profile, email, offline_access as required by your SSSD build | ☐ |
| O4 | Admin consent | Tenant-wide for pilot | ☐ |
| O5 | Pilot users in pilot group | Same group as Intune pilot where possible | ☐ |
| O6 | Conditional Access for **user** sign-in | MFA / compliant device **after** device path is green — do not block lab OIDC smoke with “require compliant” until devices enroll | ☐ |
| O7 | Optional: CARs / break-glass | Emergency access accounts excluded | ☐ |
| O8 | Optional: Hybrid / on-prem identity | Only if UID/GID hybrid is still required | ☐ |

Fill `ltz_microsoft.tenant_id`, `tenant_domain`, `pilot_user_upn` in `vars/ltz.yml`.

---

## 3. Host-side checklist

| # | Task | Done |
|---|------|------|
| H1 | SSSD + OIDC provider packages installed (goldimage / existing role) | ☐ |
| H2 | `/etc/sssd/sssd.conf` points at tenant issuer | ☐ |
| H3 | Clock sync (NTP) — OIDC is time-sensitive | ☐ |
| H4 | `realm`/`id`/`sssctl` user lookup succeeds | ☐ |
| H5 | Interactive login (GDM or SSH) succeeds for pilot UPN | ☐ |
| H6 | Device agent still attests (`status.json` attested=true) | ☐ |

SSSD config is **not** re-implemented in this monorepo’s MVP client tree if it already lives in goldimage/`sssd-hybrid`. Staging means **pointing that config at the tenant** and recording evidence.

---

## 4. Suggested test order (next)

```text
1. Lab device path remains green (already proven)
2. Create/confirm Entra app registration (O1–O4)
3. Stage one workstation with SSSD config + pilot user
4. Capture: id pilot@tenant, login log, sssd domain status
5. Only then: Intune enroll + CA require compliant for apps
6. 802.1X pilot when network team trusts device CA
```

---

## 5. Explicit non-goals for this staging pass

- Entra **CBA** (user cert passwordless) — Future  
- Using user OIDC tokens for **machine 802.1X** — forbidden  
- Replacing thin attestor with “user logged in” as device trust  

---

## 6. Related

- [entra-azure-checklist.md](entra-azure-checklist.md) — device/Intune  
- [microsoft-path.md](microsoft-path.md)  
- [../architecture/MVP-AND-FUTURE-STATE.md](../architecture/MVP-AND-FUTURE-STATE.md)  
- [../runbooks/linux-zero-trust-entra.md](../runbooks/linux-zero-trust-entra.md)  
