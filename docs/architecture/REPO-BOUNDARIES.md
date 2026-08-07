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
- **Ansible role(s)** to install agent and **machine 802.1X (EAP-TLS)** the same way prod will  

**Must not import:** Proxmox, lab inventory, step-ca lab passwords, docker-compose lab stacks.

### ltz-attestor (`services/attestor/`)

Thin attestation service: verify evidence → mint short-lived ticket **and device client cert** (MVP 802.1X).  
Configurable CA backend (embedded openssl device CA, lab step-ca, **or** enterprise API via config, not code forks).

### ltz-collector (`services/collector/`)

Accepts agent reports only with valid ticket; mock Intune sink + interface for Graph later.

### ltz-lab (`lab/`)

- Terraform/OpenTofu for Proxmox VMs (vTPM, network)  
- Lab CA, lab RP, lab enroll bootstrap, **lab FreeRADIUS** (MVP 802.1X)  
- Ansible that **configures lab VMs** and may *invoke* client roles against lab hosts  
- Evidence scripts for demos  

Lab playbooks **call** client roles via path or galaxy requirement — they do not embed client logic.

### workstation-environment (docs)

Architecture, runbooks, executive packs, agile imports — no runtime dependency for hosts.

---

## 3. Dependency rule

```text
client/  ──depends on──►  attestor API contract (OpenAPI/proto), not lab implementation
collector/  ──depends on──►  same ticket verification
lab/  ──may depend on──►  client roles + attestor + collector images/charts
prod AWX  ──may depend on──►  client roles only (never lab/)
```

---

## 4. CI expectations

| Tree | Lint / test |
|------|-------------|
| client | Shellcheck, ansible-lint, unit tests for agent |
| attestor / collector | Unit + contract tests; no Proxmox |
| lab | terraform validate, ansible-lint; optional integration job |

---

## Network client (802.1X) — MVP

| Path / concern | Repo |
|----------------|------|
| `wpa_supplicant` / NetworkManager EAP-TLS profile, cert paths, renewal | **`client/`** (`ltz_8021x` role) |
| Device cert mint API | **`services/attestor/`** (`LTZ_ATTESTOR_ISSUE_DEVICE_CERT=1`) |
| Lab FreeRADIUS + device CA trust | **`lab/`** (`lab_radius`, wired into `ansible-mvp`) |
| Production RADIUS / NPS | Network team — pilot in M2; not deferred to Future |

802.1X is a **MVP consumer** of the device cert; it does not own a separate trust root. See [device-8021x-eap-tls.md](device-8021x-eap-tls.md).
