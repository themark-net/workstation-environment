# Repository Boundaries

**Purpose:** Clear separation so **production client code** has **zero dependency** on lab infrastructure, and lab code only provisions disposable environments.

**Last updated:** 2026-08-07

---

## 1. Map

| Logical repo | Path in this design repo (reference) | Ships to production? | Depends on lab/? |
|--------------|--------------------------------------|----------------------|------------------|
| **workstation-environment** | `.` (docs, imports) | Docs only | No |
| **ltz-client** | [`client/`](../../client/) | **Yes — primary** | **No** |
| **ltz-attestor** | [`services/attestor/`](../../services/attestor/) | **Yes** (service) | **No** |
| **ltz-collector** | [`services/collector/`](../../services/collector/) | **Yes** (service) | **No** |
| **ltz-lab** | [`lab/`](../../lab/) | **No** | N/A (is the lab) |
| **goldimage** | external | Yes (admin baseline) | No |
| **sssd-hybrid** | external | Yes (done) | No |
| **zt-awx-config** | future external | Yes (mgmt) | No |
| **zt-spire-config** | future external | Future | No |

Paths under this repo are **canonical reference trees**. When production testing starts, extract `client/`, `services/attestor/`, and `services/collector/` into their own Git repos **without** copying `lab/`.

---

## 2. What each contains

### ltz-client (`client/`)

Production-shaped **host** artifacts:

- Trust / compliance **agent** scripts and unit files  
- **Attestor client** (calls remote attestor; no lab URLs hard-coded — use vars)  
- **Intune** discovery script + rules JSON (uploadable artifacts)  
- **Ansible role(s)** to install agent on a real workstation the same way prod will  

**Must not import:** Proxmox, lab inventory, step-ca lab passwords, docker-compose lab stacks.

### ltz-attestor (`services/attestor/`)

Thin attestation service: verify evidence → mint short-lived ticket/cert.  
Configurable CA backend (lab step-ca **or** enterprise API via config, not code forks).

### ltz-collector (`services/collector/`)

Accepts agent reports only with valid ticket; mock Intune sink + interface for Graph later.

### ltz-lab (`lab/`)

- Terraform/OpenTofu for Proxmox VMs (vTPM, network)  
- Lab CA, lab RP, lab enroll bootstrap  
- Ansible that **configures lab VMs** and may *invoke* client roles against lab hosts  
- Evidence scripts for demos  

Lab playbooks **call** client roles via path or galaxy requirement — they do not embed client logic.

### workstation-environment (this repo root docs)

Architecture, Entra REQ catalog, executive/implementation docs, Jira/GitLab imports.  
**Not** a runtime dependency of client or services.

---

## 3. Dependency rule

```text
lab/  ──may install──►  client/ roles on lab VMs
lab/  ──may deploy──►  services/* as lab instances
client/  ──must not──►  import lab/
services/*  ──must not──►  import lab/
docs  ──describe──►  all of the above
```

---

## 4. Extraction checklist (when splitting GitHub repos)

1. Create `ltz-client`, `ltz-attestor`, `ltz-collector` empty repos.  
2. Copy trees; keep LICENSE/README; set CI on each.  
3. Pin versions in lab Ansible via git tags.  
4. Leave stubs/README links in this design repo pointing at the new remotes.  
5. Production AWX projects point only at `ltz-client` (+ goldimage), never at `lab/`.

---

## 5. Related

- [MVP-AND-FUTURE-STATE.md](MVP-AND-FUTURE-STATE.md)  
- [../../client/README.md](../../client/README.md)  
- [../../lab/README.md](../../lab/README.md)  
