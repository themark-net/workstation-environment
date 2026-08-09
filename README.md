# Workstation Environment

**Linux Zero Trust (LTZ)** on Microsoft Entra / Intune / Conditional Access — device trust first.

| Already done | MVP now | Future (not MVP) |
|--------------|---------|------------------|
| SSSD OIDC → Entra user login | Compliant Linux device in CA | Entra CBA / Hello-class user |
| Lab dual-path + 802.1X green | Same code on real hosts + tenant | SPIRE, full AWX, prod MAA |

---

## Status & shortest path: lab MVP → prod MVP

**Where we are:** Lab MVP is **built and proven** (Proxmox, attestor tickets, Intune pilot path, 802.1X eapol SUCCESS). Client Ansible is **one playbook + one vars file**. What’s left for **prod MVP** is mostly **deploy services + tenant admin**, not new architecture.

### Done (lab MVP)

| Item | Evidence |
|------|----------|
| Thin attestor + challenge/HMAC (+ MAA plug-in stub) | `services/attestor`, lab RP |
| Dual host class: workstation (Intune GUI) + server (headless) | `make ansible-mvp` |
| Intune custom compliance artifacts | `client/intune/*` (upload in portal) |
| Ticket-gated device cert + FreeRADIUS EAP-TLS | `make ansible-8021x` → SUCCESS |
| Host bootstrap (no second playbook tree) | `client/ansible` + `vars/ltz.yml` |
| Transition docs | `docs/deployment/` |

### Remaining for prod MVP (ordered — do only this)

```text
1. Deploy control plane (real/dev)
   services/attestor + collector on a host you control
   backend=local until MAA is licensed

2. Point client vars (same Ansible as lab)
   cp client/ansible/vars/ltz-microsoft-dev.yml.example → vars/ltz.yml
   set attestor/collector URLs, join token, pilot UPN/group

3. Bootstrap pilot hosts
   ansible-playbook … bootstrap-host.yml
   workstations: enroll intune-portal as pilot user

4. Tenant (Entra/Intune) — checklist only
   upload discovery.sh + rules.json → compliance policy → pilot group
   after Compliant green: CA report-only → require compliant device
   see docs/deployment/entra-azure-checklist.md

5. Stop. That is prod MVP.
```

**Prod MVP done when:** pilot Linux shows **Intune Compliant** from attestor ticket, and Conditional Access can require compliant device for pilot apps.

### Explicitly not on the critical path

| Defer | Why |
|-------|-----|
| Cloud PKI / prod 802.1X | Same trust model as lab; network team later |
| MAA as attestor backend | Swap env on attestor host; E5/MAA not required for MVP |
| Entra CBA (user) | Separate plane — Future |
| SPIRE / workload MS CA | Future |
| AWX HA / GPO parity | Management depth later |

### Distance (honest)

```text
Lab MVP code ████████████████████  ~done
Prod MVP code ████████████░░░░░░░░  ~70%  (host + services ready; tenant + deploy left)
Prod MVP live ░░░░░░░░░░░░░░░░░░░░  ~0–20% (needs your tenant + one real pilot run)
Future state  ░░░░░░░░░░░░░░░░░░░░  out of scope for this path
```

---

## Commands

**Lab (air-gap proof)**

```bash
cd lab
make tf-apply && make wait-ssh
make ansible-site-full    # bootstrap + mvp + 802.1X
make validate
```

**Prod / microsoft-dev hosts (same client roles)**

```bash
cd client/ansible
cp vars/ltz-microsoft-dev.yml.example vars/ltz.yml   # fill
cp inventory/hosts.example.yml inventory/hosts.yml
ansible-playbook -i inventory/hosts.yml playbooks/bootstrap-host.yml
# then: human Intune enroll + portal upload of client/intune/*
```

---

## Trees

```text
client/          # prod host agent + Intune artifacts + Ansible  (vars/ltz.yml)
services/        # attestor, collector
lab/             # Proxmox + lab glue only
docs/deployment/ # lab proof → microsoft path → entra checklist
docs/            # architecture
```

## Docs

| Doc | Use |
|-----|-----|
| [docs/deployment/README.md](docs/deployment/README.md) | Lab → Microsoft transition detail |
| [docs/deployment/entra-azure-checklist.md](docs/deployment/entra-azure-checklist.md) | Portal steps for prod MVP |
| [docs/architecture/MVP-AND-FUTURE-STATE.md](docs/architecture/MVP-AND-FUTURE-STATE.md) | Full phasing |
| [client/README.md](client/README.md) | Host bootstrap |
| [lab/README.md](lab/README.md) | Lab deploy |

## Base workstation playbook (unrelated baseline)

```bash
ansible-playbook -i inventory.yml setup-workstation.yml --become
```
