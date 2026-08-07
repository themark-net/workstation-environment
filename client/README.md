# ltz-client (production client reference tree)

**Standalone production-shaped host components for LTZ MVP device trust.**  
**No dependency on `lab/`.** Configure endpoints via Ansible vars or environment.

When ready for production testing, extract this directory to its own Git repository (`ltz-client`).

---

## Contents

| Path | Purpose |
|------|---------|
| `agent/` | Trust/compliance agent (status + attest orchestration) |
| `attestor-client/` | Calls remote thin attestor |
| `intune/` | Discovery script + rules JSON (upload to Intune) |
| `ansible/` | Roles to install agent on a real workstation |

---

## Install (production-like)

```bash
ansible-playbook -i inventory.ini ansible/playbooks/site.yml \
  -e attestor_url=https://attestor.example.com \
  -e collector_url=https://collector.example.com
```

Inventory is **your** hosts file — not lab inventory.

---

## Runtime flow (MVP)

```text
systemd timer → ltz-trust-agent
  → gather local health
  → attestor-client: POST /v1/attest
  → store ticket under /var/lib/ltz-trust/
  → POST status to collector (with ticket)
  → write status.json for Intune discovery script
```

Intune discovery script **only passes** if a **non-expired ticket** is present (and optional claims). It does not invent posture without attestor success.

---

## Intune plug-in day

1. Enroll device (Company Portal).  
2. Upload `intune/discovery.sh` as custom compliance discovery script.  
3. Upload `intune/rules.json`.  
4. Assign compliance policy to pilot group.  

No code change required if paths match role defaults.

---

## Architecture

See design repo: `docs/architecture/MVP-AND-FUTURE-STATE.md`, `REPO-BOUNDARIES.md`.
