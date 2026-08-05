# Runbook: AWX / Ansible as GPO-Class Policy Plane for Linux

**Goal:** Make managed Linux as **reliable and defendable** as Entra-joined Windows for architects who trust **compliance + continuous configuration** more than classic AD GPO—and who know GPO itself drifts.

**Constraint:** Intune's native Linux settings surface is thinner than Windows. We **close that gap** with AWX Ansible (already used for SSSD OIDC, MDATP, Nessus) plus Intune compliance as the Entra-facing truth bit.

---

## 1. Reframe: what Windows architects actually trust

They are usually **not** claiming "GPO is perfect." They claim:

1. Device is **managed by the org**.
2. **Health/compliance** is evaluated before access (Intune → CA).
3. Configuration has a **desired state** and **telemetry** when wrong.
4. User auth is **phishing-resistant** where required.

| Belief | Reality | Linux answer |
|--------|---------|--------------|
| "Entra joined > AD" | Continuous **cloud access control** + device compliance | Same CA + Intune Linux |
| "GPO enforces settings" | Often **eventual**; drift exists | AWX **scheduled enforce** + check mode |
| "MDM is always on" | Compliance is the **gate**, not infinite settings | Intune compliance **fail closed** |
| "Linux can't do that" | Native Intune depth is thinner | **AWX depth + compliance bridge** |

**Reliability slogan for this program:**

> *Desired state is applied by AWX. Truth is measured by the host agent. Access is granted only when Intune says compliant.*

That is stronger than "we have Ansible playbooks" and comparable to "Entra + Intune compliance," not weaker than nostalgic perfect GPO.

---

## 2. Where Linux is thinner (honest) and how we thicken it

| Capability | Windows | Linux native Intune | Our thickening |
|------------|---------|---------------------|----------------|
| Settings catalog / thousands of CSP | Deep | Shallow | **AWX roles** as policy packs |
| Autopilot / ESP | Yes | No | Image + first-boot + enroll checklist |
| Win32 / LOB apps | Yes | Limited | Package modules / flatpak / internal repos |
| Compliance signals | Rich | Distro, encryption, password, **custom** | Custom scripts + **privileged status agent** |
| Continuous re-apply | Intune + GPO | Limited | **AWX schedule** (e.g. every 1–4h) |
| Drift visibility | Intune, Defender, etc. | Weaker | AWX job status + agent `policy_gen` + Nessus/MDATP |

Custom compliance discovery on Linux runs in **user context** and cannot elevate—so privileged checks **must** be done by a **root agent** (deployed by Ansible) that writes a user-readable status file. See [intune-compliance-bridge.md](intune-compliance-bridge.md).

---

## 3. Control mapping: GPO → AWX

| GPO-era concept | AWX / Linux equivalent |
|-----------------|------------------------|
| GPO object | Ansible **role** or **playbook** (versioned in git) |
| OU linking | AWX **inventory groups** / smart inventories (env, role, compliance tier) |
| Security filtering / item-level targeting | Group vars, host vars, `when:` by tag/group |
| gpupdate / refresh interval | AWX **schedule** + optional pull-mode runner |
| RSOP / gpresult | AWX job stdout + `ansible-playbook --check` report + host `policy_gen` |
| WMI filters | Facts + group membership + custom facts from agent |
| Central Store templates | Git repo (this project + ansible-workstation-environment) |
| Enforced GPO | Role tasks with force/template overwrite + file attributes |
| Preference (non-enforced) | Templates only if missing; document as non-blocking |

### Policy pack examples (expand existing roles)

| Pack | Contents |
|------|----------|
| `auth_sssd_oidc` | Existing SSSD OIDC (keep) |
| `auth_tpm_cba` | tpm2-pkcs11, NSS hooks, enrollment helpers |
| `ms_broker_edge` | Identity Broker, Edge, repos |
| `intune_prep` | Intune portal deps, enrollment prep |
| `trust_agent` | systemd timer → `/var/lib/org-trust/status.json` |
| `disk_crypto` | LUKS assertions / helpers (not reckless re-encrypt) |
| `security_baseline` | sshd, sudo, sysctl, journald, unattended upgrades policy |
| `mdatp` | Existing |
| `nessus` | Existing |
| `telemetry` | Optional: ship agent metrics to SIEM |

Each pack has:

- **apply** play
- **check** (diff) play
- **assert** tasks that fail the job if critical drift remains
- **version** / `policy_gen` integer written on success

---

## 4. AWX operating model (production reliability)

### 4.1 Inventories

- Dynamic or static groups: `linux_workstations`, `linux_pilot`, `linux_breakglass_exclude`
- Source of truth: CMDB / Entra group sync / AWX smart inventory
- Every managed host **must** be in inventory; unknown hosts fail network admission or get no secrets

### 4.2 Job types

| Job | Schedule | On failure |
|-----|----------|------------|
| **Enforce baseline** | Every 1–4 hours | Ticket + host marked degraded in status.json |
| **Check/diff only** | Daily | Report to SecOps dashboard |
| **Emergency harden** | Manual | Change window |
| **Cert renew helpers** | Daily | Alert < 30 days |
| **Agent health** | Hourly (on-box timer) | compliance fail if stale |

### 4.3 Idempotency and "GPO-like" enforcement

- Prefer `template`, `copy` with checksum, `lineinfile` carefully, `blockinfile` with markers
- **Managed file header:** `# Managed by AWX policy_gen=N — do not edit`
- Critical paths: if local change detected, **overwrite** (enforced) and log
- Non-critical: report only

### 4.4 AuthN to hosts

- Prefer SSH certs or short-lived creds; break-glass local account monitored
- AWX credential rotation SLA
- No long-lived shared root passwords in cleartext

### 4.5 Git as the only policy authoring path

- PRs required; CODEOWNERS for `security_baseline` and `auth_*`
- Tag releases; AWX projects pin to tag/semver for prod
- Pilot consumes `main` or `next`; prod consumes release tags

---

## 5. Closing the loop with Intune (this is the Entra reliability story)

Architects trust Entra join because **non-compliance blocks access**. Mirror that:

```text
AWX applies policy_gen=N
        │
        ▼
trust_agent evaluates host (TPM CBA, LUKS, Secure Boot, services, policy_gen age)
        │
        ▼
/var/lib/org-trust/status.json
        │
        ▼
Intune custom compliance discovery (user context reads file)
        │
        ▼
Compliant / Not compliant
        │
        ▼
Conditional Access allow / deny
```

**Stale policy is non-compliant:**

- `policy_gen` missing or older than SLA (e.g. no successful AWX apply in 8–24h) → fail
- Agent `ts` older than 24h → fail
- `tpm_cba_cert` false → fail

Thus: a host that "has Ansible installed but hasn't converged" **loses resource access**—same philosophy as Intune compliance on Windows.

---

## 6. Comparison: "Is this as good as Entra-managed Windows?"

| Criterion | Entra Windows | This Linux design | Verdict |
|-----------|---------------|-------------------|---------|
| Access gated on device health | Yes | Yes (Intune) | **Parity** |
| Phishing-resistant user auth | Hello/FIDO/CBA | TPM CBA | **Parity of strength** |
| Continuous config | Intune/GPO | AWX enforce | **Parity of intent** |
| Breadth of native settings | Higher | Lower natively; AWX fills | **Accept + compensate** |
| Autopilot zero-touch | Yes | Image + enroll | **Process parity, not product** |
| Auditability | Strong | Entra + Intune + AWX jobs | **Parity if retained** |

Do **not** claim feature-identical MDM. Claim **control-identical Zero Trust access** with **stronger explicit drift handling** than many GPO estates.

---

## 7. Implementation backlog (AWX expansion)

1. Inventory model + groups for pilot/prod
2. Role split from monolithic `setup-workstation.yml` into policy packs
3. `trust_agent` role + systemd timer
4. `auth_tpm_cba` role (packages + helpers; enrollment workflow)
5. Job templates: enforce, check, cert-expiry
6. Notifications: AWX → Teams/email/SIEM on failed enforce
7. Dashboard: % compliant Linux, mean time to remediate, policy_gen distribution
8. Document RACI: who approves baseline changes (same as GPO change board)

---

## 8. Anti-patterns

| Anti-pattern | Why it fails the architect test |
|--------------|----------------------------------|
| Ansible only at imaging, never again | Silent drift; no reliability |
| Compliance always green hardcoded | Fraudulent gate |
| Different CA policies excluding Linux forever | Second-class access; funds die |
| Manual snowflake packages on gold images only | No continuous state |
| Root SSH with password for AWX | Undermines the trust story |

---

## 9. Related

- [linux-zero-trust-entra.md](linux-zero-trust-entra.md)
- [tpm-cba-no-usb.md](tpm-cba-no-usb.md)
- [intune-compliance-bridge.md](intune-compliance-bridge.md)
