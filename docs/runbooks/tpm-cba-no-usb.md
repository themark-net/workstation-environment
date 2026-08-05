# Runbook: TPM-Backed Entra CBA (No USB Required)

**Requirement:** Day-to-day phishing-resistant Entra authentication on Linux **must not require a USB security key**. The private key lives in the **platform TPM 2.0**, exposed via **PKCS#11** (`tpm2-pkcs11`), used as a **virtual smart card** for **Microsoft Entra certificate-based authentication (CBA)**.

USB/PIV tokens remain optional for **break-glass / recovery**, not the primary UX.

---

## 1. Why this path

| Goal | Implementation |
|------|----------------|
| UX parity with Windows Hello (device-bound, PIN) | TPM key + PIN on PKCS#11 token |
| Microsoft-accepted phishing-resistant method | Entra **CBA** (auth strength) |
| No parallel IdP | Same Entra tenant + enterprise PKI |
| No dongle friction | **No USB for primary path** |

This is **not** FIDO2 "passkey in TPM" (Hello). It is **X.509 CBA** with Hello-class **hardware binding**.

---

## 2. Prerequisites

### Hardware / OS

- TPM 2.0 present, owned, not in bad state
- Supported managed distro for Intune + broker (target fleet: **Ubuntu Desktop 24.04/26.04 LTS** and/or **RHEL 9/10** per current Microsoft matrices)
- Secure Boot enabled (recommended; enforce via compliance when ready)

### Tenant / PKI

- Enterprise CA issues **client authentication** certificates
- CA chain + **HTTP CRL** registered in Entra for CBA
- CBA authentication method **enabled** for pilot/prod groups
- Username binding (prefer high-affinity → `certificateUserIds` where UPN-in-SAN is not used)
- Authentication binding: treat these certs as **multifactor** when policy OID/issuer rules allow
- Identity Broker ≥ 2.0.2 for Linux PRMFA/CBA paths where applicable

### Packages (install via AWX role)

Typical set (names vary by distro):

- `tpm2-tools`, `tpm2-abrmd` (as required), `libtpm2-pkcs11`, `tpm2-pkcs11-tools`
- `p11-kit`, `opensc` (optional stack), `libnss3-tools` / `nss-tools`
- `microsoft-identity-broker`, Microsoft Edge
- Intune portal / enrollment prep packages

---

## 3. Architecture

```text
User PIN
   │
   ▼
tpm2-pkcs11 token (keys non-exportable in TPM)
   │
   ├── NSS DB / p11-kit  →  Edge / Identity Broker
   │                           │
   │                           ▼
   │                      Entra CBA (mTLS client cert)
   │                           │
   │                           ▼
   │                      Tokens / cloud SSO
   │
   └── Status agent reports: tpm_present, cba_cert_valid, pin_token_ready
                              → Intune custom compliance
```

---

## 4. Enrollment procedure (per user on device)

Automate as much as possible with AWX; interactive steps only where PIN or user binding requires a human.

### 4.1 Initialize TPM PKCS#11 token (once per machine or per user policy)

Conceptual flow (exact CLI may track distro package versions):

1. Ensure TPM resource manager is running.
2. `tpm2_ptool init` (or org-standard init) for the PKCS#11 store.
3. `tpm2_ptool addtoken` — create token label (e.g. `entra-cba`) with **user PIN** (and SO PIN escrowed per org secret standard).
4. **Generate keypair inside TPM** (RSA 2048+ or org standard). **Do not** import an existing soft private key if non-exportability is required.

### 4.2 Certificate request and issuance

1. Create CSR from the TPM-resident public key (openssl engine / tpm2-pkcs11 / pkcs11-tool pattern per org).
2. Submit CSR to **enterprise CA** using the **same template family** as smart card / user auth certs where possible (EKU client auth; SAN UPN or serial/SKI mapping).
3. Retrieve signed certificate.
4. `tpm2_ptool addcert` (or equivalent) — attach cert to key id in the token.
5. Ensure Entra username binding succeeds (UPN in SAN **or** `certificateUserIds` populated).

### 4.3 Make cert visible to browser / broker

1. User NSS DB: `~/.pki/nssdb` (create if missing).
2. Register PKCS#11 module (`libtpm2_pkcs11.so`) via `modutil` / p11-kit.
3. Verify cert listed; test Entra "Sign in with certificate" (My Apps / Edge).

### 4.4 Record success for compliance

Trust agent writes `/var/lib/org-trust/status.json` fields such as:

```json
{
  "ts": 1785890000,
  "tpm_present": true,
  "tpm_cba_key": true,
  "tpm_cba_cert": true,
  "tpm_cba_cert_not_after": "2027-08-05T00:00:00Z",
  "secure_boot": true,
  "luks": true,
  "policy_gen": 42
}
```

---

## 5. Day-to-day user experience

1. User unlocks session (SSSD OIDC or local policy — **unchanged**).
2. Edge / app needs Entra → broker or browser requests client cert.
3. User enters **TPM token PIN** (and optional touch if configured).
4. Entra validates cert (CA trust, CRL, binding) → MFA-strength if configured → access.
5. **No USB key insert/remove cycle.**

---

## 6. Lifecycle

| Event | Action |
|-------|--------|
| Cert near expiry | AWX job: re-CSR or renew; alert if < 30 days |
| User leaves | Revoke cert (CRL); Intune retire; disable Entra account |
| TPM / motherboard replace | New keygen + CSR; old cert revoke; re-enroll Intune if hardware identity changes |
| PIN lockout | SO PIN / helpdesk runbook (escrow); never store user PIN in Ansible vault as shared secret |
| Compromise | Revoke cert; force compliance fail; wipe/rebuild if needed |

---

## 7. Security requirements (non-negotiable)

1. Key **generated in TPM**, not imported from disk PEM for production.
2. PKCS#11 DB / auth values protected; root-only where applicable; user PIN only for user token.
3. SO PIN in enterprise secret store with dual control.
4. CRL reachable by Entra; revoke tested in pilot.
5. Do not disable password method tenant-wide without break-glass; use **CA** to block password for apps.
6. CA upload / CBA enablement is **tier-0** (PIM, monitoring).

---

## 8. Validation checklist

- [ ] `tpm2_getcap properties-fixed` (or equivalent) shows TPM
- [ ] PKCS#11 token lists key + cert
- [ ] Private key operation requires PIN
- [ ] Entra sign-in log shows **certificate** auth success
- [ ] Auth strength / MFA claim as designed
- [ ] Works offline-to-online after reboot without USB
- [ ] Custom compliance green for `tpm_cba_*`
- [ ] Revocation test fails sign-in within CRL SLA

---

## 9. Break-glass

- Separate **break-glass** Entra accounts excluded from strict CA (monitored).
- Optional **USB PIV** enrolled only for admin/recovery personas—not default fleet.
- Temporary Access Pass (TAP) for bootstrap only, time-bound.

---

## 10. References

- [tpm2-pkcs11](https://github.com/tpm2-software/tpm2-pkcs11)
- [Entra CBA setup](https://learn.microsoft.com/en-us/entra/identity/authentication/how-to-certificate-based-authentication)
- [Linux Identity Broker / smart card & CBA](https://learn.microsoft.com/en-us/entra/identity/devices/sso-linux)
