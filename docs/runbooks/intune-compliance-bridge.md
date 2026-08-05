# Runbook: Intune Linux Compliance Bridge

Turns **host reality** (TPM-CBA, encryption, AWX policy generation, agents) into the **Intune compliance bit** Conditional Access already trusts for Windows.

---

## 1. Why a bridge is required

- Intune **built-in** Linux compliance: allowed distro/version, encryption, password, custom.
- Linux **custom discovery scripts run as the user** — cannot reliably read root-only state.
- Therefore: **privileged agent** (Ansible-deployed) evaluates and writes **status.json**; discovery only **reads** it.

---

## 2. Status file contract

**Path:** `/var/lib/org-trust/status.json`  
**Mode:** `0644` (or ACL allowing the interactive user / Intune app user to read)  
**Owner:** `root:root`  
**Update:** systemd timer every 15–30 minutes + after AWX enforce

### Example schema

```json
{
  "schema": 1,
  "ts": 1785890000,
  "hostname": "ws-linux-042",
  "policy_gen": 42,
  "policy_gen_ts": 1785889000,
  "secure_boot": true,
  "luks": true,
  "luks_tpm_sealed": true,
  "tpm_present": true,
  "tpm_cba_key": true,
  "tpm_cba_cert": true,
  "tpm_cba_cert_not_after": "2027-08-05T00:00:00Z",
  "sssd_oidc": true,
  "mdatp": true,
  "nessus": true,
  "intune_portal": true,
  "broker": true,
  "attestation": "pass",
  "errors": []
}
```

### Freshness rules (custom compliance operands)

| Field | Pass condition (example) |
|-------|---------------------------|
| `ts` age | < 86400 seconds |
| `policy_gen_ts` age | < 86400 seconds (tune to AWX SLA) |
| `tpm_cba_cert` | true |
| `luks` | true |
| `secure_boot` | true (when fleet-ready) |
| `mdatp` / `nessus` | true |
| `tpm_cba_cert_not_after` | > now + 14 days |

---

## 3. Agent design (systemd)

**Unit:** `org-trust-agent.service` + `org-trust-agent.timer`  
**Deployed by:** AWX role `trust_agent`  
**Runs as:** root  
**Actions:**

1. Probe TPM, PKCS#11 token/cert presence (non-interactive checks).
2. Probe LUKS, Secure Boot, service active states.
3. Read last AWX success marker (`/var/lib/org-trust/policy_gen` written by enforce playbook).
4. Atomic write status.json (`write tmp + rename`).
5. Optional: emit structured log line to journald for SIEM.

**Hardening:**

- Agent script mode `0755`, owned root
- No network required for local probes (attestation network optional later)
- Failures set booleans false and populate `errors[]` — never fake true

---

## 4. Intune configuration

### Built-in policy

- Allowed distributions / versions for fleet
- Require device encryption
- Password settings as org standard

### Custom compliance

1. Upload **discovery script** (POSIX) that:
   - Reads `/var/lib/org-trust/status.json`
   - Emits `SettingName` / values Intune JSON expects (integers/bools/strings)
   - If file missing/unreadable/stale → emit failing values
2. Upload **JSON rules** requiring pass conditions above
3. Assign to **all Linux corporate users/devices** in scope
4. Compliance action: mark noncompliant (CA handles block)

**Note:** Keep discovery logic dumb and pure; all intelligence in the root agent.

---

## 5. Conditional Access

| Policy | Settings |
|--------|----------|
| Cloud apps (M365 + LOB) | Grant: **require compliant device** + **phishing-resistant MFA** (includes CBA) |
| Platforms | Include Linux (and Windows) |
| Report-only | Pilot first |
| Break-glass | Excluded accounts, monitored |

Linux and Windows can share policies if both emit compliant + phishing-resistant signals.

---

## 6. Failure modes

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Always noncompliant | status.json missing | Deploy trust_agent; fix permissions |
| Intermittent | timer stopped | AWX re-enforce; alert on timer |
| Compliant but no CBA | Cert not in TPM / binding | tpm-cba enrollment |
| CA blocks after AWX outage | policy_gen stale by design | Restore AWX; re-run enforce |
| User context cannot read file | mode too strict | 0644 or ACL |

---

## 7. Acceptance tests

1. Healthy pilot host → Compliant within one Intune sync after agent run.
2. Stop agent timer → becomes Noncompliant within freshness window + sync.
3. Remove TPM cert → Noncompliant; CA denies protected app.
4. Restore cert + agent → Compliant; access restored.
5. Sign-in log shows CBA; device compliance history shows transitions.

---

## 8. Related

- [linux-zero-trust-entra.md](linux-zero-trust-entra.md)
- [tpm-cba-no-usb.md](tpm-cba-no-usb.md)
- [ansible-awx-gpo-parity.md](ansible-awx-gpo-parity.md)
- [Custom compliance](https://learn.microsoft.com/en-us/intune/device-security/compliance/custom-settings)
