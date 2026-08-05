# Runbook: Linux Zero Trust with Microsoft Entra (Unified Control Plane)

**Status:** Architecture / implementation guide  
**Audience:** Security architects (Windows-oriented), Linux platform, IAM  
**Last updated:** 2026-08-05  
**Hard requirement:** **No USB authenticator for day-to-day Entra passwordless** — platform **TPM** holds the user CBA private key (see [tpm-cba-no-usb.md](tpm-cba-no-usb.md)).

---

## 1. Executive summary (funding narrative)

We are **not** building a parallel Linux identity or trust stack.

Linux workstations join the **same Zero Trust decision plane** already used for Windows:

| Plane | Shared Microsoft / enterprise control | Windows proof | Linux proof |
|-------|----------------------------------------|---------------|-------------|
| **User (phishing-resistant)** | Entra auth methods + authentication strengths | Windows Hello / passkey / CBA | **Entra CBA** with key in **platform TPM** (PKCS#11) |
| **Device (managed + healthy)** | Intune compliance → Entra "compliant device" | Autopilot + Intune | Golden image + Intune enroll + compliance |
| **Access** | Conditional Access | Same policies | Same policies |
| **OS configuration depth** | (Windows: Intune/GPO/Settings Catalog) | Deep native MDM | **AWX Ansible** continuous apply + compliance fail-closed |

**Local OS login** (SSSD OIDC, already deployed via Ansible) remains a separate UX path and does not need to equal Hello for cloud access. **Resource access** is gated by CA: phishing-resistant MFA (CBA) + compliant device.

### One paragraph for Windows architects

> Linux is another **client implementation** of controls you already fund—Entra CBA, Intune compliance, Conditional Access—not a second security program. User private keys are **non-exportable in the device TPM** (Hello-class hardware binding, certificate protocol). Device trust uses **Intune enrollment and compliance**, the same bit CA already evaluates for Windows. AWX Ansible provides GPO-class continuous configuration and feeds compliance so Linux is not "hope and hop" management.

---

## 2. What we explicitly do *not* do

| Anti-pattern | Why rejected |
|--------------|--------------|
| Fake Autopilot / OA3 hash upload for Linux | Wrong protocol; no Linux ZTD client |
| Separate Linux-only IdP for corporate access | Parallel island; weaker CA integration |
| Separate Linux-only CA for Entra | Reuse **existing enterprise PKI** already trusted for CBA |
| USB security key required for daily UX | Violates UX parity with Hello-on-device; **TPM is required** |
| Rely only on SSSD OIDC for "compliant device" | OIDC proves **user**, not device health |
| Claim "Intune on Linux = Windows settings catalog" | Dishonest; we close the gap with AWX + compliance |

---

## 3. Trust model (three planes + management)

```text
┌─────────────────────────────────────────────────────────────┐
│ PLANE 1 — USER credential (phishing-resistant)              │
│  TPM-held X.509 → Entra CBA (MFA-strength binding rules)    │
│  Identity Broker + Edge for cloud SSO                       │
│  Local: SSSD OIDC (existing) — separate session path        │
├─────────────────────────────────────────────────────────────┤
│ PLANE 2 — DEVICE trust                                      │
│  Corporate image · LUKS (+ TPM seal) · Intune enrolled      │
│  Compliance: encryption, distro, custom (agent status)      │
├─────────────────────────────────────────────────────────────┤
│ PLANE 3 — ACCESS                                            │
│  Conditional Access: phishing-resistant MFA + compliant      │
│  Same policies for Windows and Linux                        │
├─────────────────────────────────────────────────────────────┤
│ PLANE 4 — OS STATE (Linux management depth)                 │
│  AWX Ansible continuous policy (GPO analogue)               │
│  MDATP · Nessus · SSSD · broker · trust agent               │
│  Drift → remediating job + non-compliant until fixed        │
└─────────────────────────────────────────────────────────────┘
```

Plane 4 is where Linux-specific tooling **closes the "thinner MDM" gap**. See [ansible-awx-gpo-parity.md](ansible-awx-gpo-parity.md).

---

## 4. TPM-CBA vs Windows Hello (honest equivalence)

| Property | Windows Hello / platform passkey | Linux TPM + Entra CBA |
|----------|----------------------------------|------------------------|
| Private key in device TPM | Yes | **Yes (required)** |
| Non-exportable key | Yes | Yes (keygen in TPM, not imported PEM) |
| PIN / UV | Yes | PIN on PKCS#11 token |
| Protocol to Entra | FIDO2 / WHfB | **X.509 CBA** |
| Entra log classification | Passkey / Hello | **Certificate-based** |
| Provisioning | First-party OS | CSR from TPM → **enterprise CA** → import cert |
| UX parity goal | PIN unlocks device-bound cred | PIN unlocks TPM token for CBA — **no USB** |

**Architect language:** *hardware-bound user certificate (virtual smart card in TPM)*, not "Linux Hello passkeys."  
**Control language:** same phishing-resistant MFA strength and CA outcomes.

Full procedure: [tpm-cba-no-usb.md](tpm-cba-no-usb.md).

---

## 5. Shared infrastructure (do not rebuild)

| Component | Action |
|-----------|--------|
| Microsoft Entra ID | Users, groups, CBA method, auth strengths |
| Enterprise PKI | Issue **user auth** certs for Linux TPM CSRs (same roots Entra trusts) |
| HTTP CRL | Internet-reachable by Entra |
| Intune | Linux enrollment + compliance policies |
| Conditional Access | Require compliant device + phishing-resistant MFA |
| MDATP / Nessus | Already Ansible-deployed; keep as sensors |
| AWX / Ansible Tower | Expand as continuous policy engine |

---

## 6. Why Entra + compliance beats classic AD (and how Linux matches)

Windows architects prefer **Entra join + Intune compliance** over pure AD because:

1. **Access is continuous and cloud-evaluated** — CA re-checks user + device signals at resource access, not only at domain logon.
2. **Device health is a first-class grant** — "require compliant device" is binary and auditable.
3. **Phishing-resistant methods** attach to the same CA engine.
4. **GPO can drift**; modern story is **MDM desired-state + compliance**, not "OU applied once."

Linux matches that **mechanically**:

| Architect concern | Windows Entra path | Linux path (this program) |
|-------------------|--------------------|---------------------------|
| Device known to org | Autopilot / Entra join + Intune | Intune enroll (corporate) |
| Health before access | Intune compliance | Intune compliance (+ custom) |
| Config enforcement | Intune / GPO / Security Baseline | **AWX continuous playbooks** |
| Drift detection | Compliance + reporting | AWX check mode / last-run + **status agent** → non-compliant |
| User phishing resistance | Hello / FIDO / CBA | **TPM CBA** |
| Audit | Entra + Intune logs | Same + AWX job history |

Reliability is not "Ansible ran once." Reliability is:

**apply continuously → measure → report compliance → CA fails closed.**

That is the same reliability model as Entra-joined Windows—not perfect GPO, but **compliance-gated access**.

---

## 7. Work packages

| WP | Deliverable | Owner skill |
|----|-------------|-------------|
| WP1 | Entra CBA enablement, bindings, MFA rules, CRL | IAM |
| WP2 | CA policies (report-only → enforce) | IAM / SecOps |
| WP3 | Image + packages (broker, Edge, tpm2-pkcs11, Intune prep) | Linux platform |
| WP4 | TPM keygen + CSR + cert lifecycle automation (AWX role) | Linux + PKI |
| WP5 | Trust status agent + Intune custom compliance | Linux + Intune |
| WP6 | AWX schedules, inventories, drift/remediate pipelines | Automation |
| WP7 | Pilot cohort, sign-in logs, access tests, GA | Joint |

---

## 8. Success criteria (no ambiguity for reliability)

A Linux client is **production-trusted** when all are true:

1. **Intune enrolled** and appears under Linux devices.
2. **Compliance = Compliant** (encryption, distro, custom: TPM-CBA ready, agent fresh, policy generation).
3. User can complete **Entra CBA** with **TPM-held cert** (no USB).
4. CA blocks password-only for protected apps.
5. AWX **policy job succeeded within SLA** (e.g. ≤ 4h); stale/missing job → custom compliance fail.
6. MDATP / Nessus agents healthy (existing roles).
7. Sign-in and device logs demonstrate CBA + compliant device claims.

---

## 9. Related documents

- [TPM-backed Entra CBA (no USB)](tpm-cba-no-usb.md)
- [AWX policy plane & GPO parity](ansible-awx-gpo-parity.md)
- [Intune Linux compliance bridge](intune-compliance-bridge.md)

## 10. References (Microsoft)

- [Entra certificate-based authentication](https://learn.microsoft.com/en-us/entra/identity/authentication/concept-certificate-based-authentication)
- [Set up Entra CBA](https://learn.microsoft.com/en-us/entra/identity/authentication/how-to-certificate-based-authentication)
- [Microsoft SSO / PRMFA on Linux](https://learn.microsoft.com/en-us/entra/identity/devices/sso-linux)
- [Linux Intune enrollment](https://learn.microsoft.com/en-us/intune/device-enrollment/guide-linux)
- [Custom compliance (Linux)](https://learn.microsoft.com/en-us/intune/device-security/compliance/custom-settings)
