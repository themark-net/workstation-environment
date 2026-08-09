# Deployment transition: lab → Microsoft demo / prod-shaped

**Goal:** One Ansible host bootstrap path. Lab and “real” (Microsoft dev or production) differ by **inventory + one vars file**, not by a second playbook tree.

```text
┌─────────────────────────────────────────────────────────────────────┐
│  1. Air-gapped lab (Proxmox + our code)                              │
│     make tf-apply → ansible-site-full (or mvp + 8021x)               │
├─────────────────────────────────────────────────────────────────────┤
│  2. Lab trust proof (this docs set)                                  │
│     Prove attestor → ticket → mint → RADIUS / Intune presentation    │
├─────────────────────────────────────────────────────────────────────┤
│  3. Identical client Ansible on real/dev hosts                       │
│     client/ansible bootstrap-host + vars/ltz.yml (microsoft-dev)     │
│     In-place: your attestor, mint, RADIUS, Intune, optional MAA      │
├─────────────────────────────────────────────────────────────────────┤
│  4. Entra / Azure admin configuration                                │
│     docs/deployment/entra-azure-checklist.md                         │
└─────────────────────────────────────────────────────────────────────┘
```

| Stage | Doc | Code entrypoint |
|-------|-----|-----------------|
| Lab deploy | [lab/README.md](../../lab/README.md) | `cd lab && make ansible-site-full` |
| Lab trust proof | [lab-trust-proof.md](lab-trust-proof.md) | Evidence commands + plane table |
| Client on any host | [client/README.md](../../client/README.md) | `bootstrap-host.yml` + `vars/ltz.yml` |
| Microsoft path | [microsoft-path.md](microsoft-path.md) | Same playbook; filled `ltz_microsoft` |
| Entra/Azure | [entra-azure-checklist.md](entra-azure-checklist.md) | Portal / Graph work |

---

## What is automated vs human

| Work | Lab | Real / Microsoft demo |
|------|-----|------------------------|
| Host packages, agent, device cert request | Ansible (`client/` roles) | **Same Ansible** |
| Thin attestor + collector | Lab `lab_attestor` on RP | Deploy `services/attestor` (+ MAA backend if licensed) |
| Device CA + ticket-gated mint | Lab `lab_ca` (step-ca) | Cloud PKI / enterprise CA fronted by mint API **or** keep cert-mint shape |
| RADIUS EAP-TLS | Lab FreeRADIUS | Corp NPS / FreeRADIUS / cloud RADIUS trusting **device CA** |
| Intune enrollment GUI | Ansible prereqs | Same prereqs |
| Custom compliance policy | Upload `client/intune/*` | Same upload |
| Conditional Access “require compliant” | N/A in pure air-gap | Portal after pilot green |
| Entra CBA (user) | Out of scope MVP | Future — separate plane |

---

## One vars surface

**File:** [`client/ansible/vars/ltz.yml.example`](../../client/ansible/vars/ltz.yml.example)

| Block | Purpose |
|-------|---------|
| `ltz_attestor_url` / `ltz_collector_url` | Device trust plane |
| `ltz_cert_mint_url` / `ltz_radius_*` | Network plane (802.1X) |
| `ltz_install_intune_*` | Workstation MDM prereqs |
| `ltz_microsoft.*` | Tenant IDs, pilot group, Cloud PKI / MAA / CA flags |

Lab inventory resolves URLs from host groups. Real hosts put concrete URLs in `ltz.yml` (or group_vars with the **same keys**).

Microsoft-shaped example: [`ltz-microsoft-dev.yml.example`](../../client/ansible/vars/ltz-microsoft-dev.yml.example).

---

## Trust planes (do not collapse)

| Plane | Artifact | Who trusts it |
|-------|----------|---------------|
| **Posture / ticket** | Short-lived attestor ticket (HMAC lab / MAA-backed) | Cert mint, collector, Intune discovery |
| **Device X.509** | Client cert from device CA | RADIUS, optional mTLS |
| **User identity** | OIDC / future CBA | SSSD, Entra apps — **not** machine 802.1X |

Attestor is a **gate to issuance**, not an issuer in the EAP-TLS chain.

---

## Quick commands

```bash
# Lab (air-gap)
cd lab
make tf-apply && make wait-ssh
make ansible-site-full    # bootstrap + mvp + 802.1X
make validate && make demo-paths

# Real / microsoft-dev host (from laptop with SSH)
cd client/ansible
cp vars/ltz-microsoft-dev.yml.example vars/ltz.yml   # edit
cp inventory/hosts.example.yml inventory/hosts.yml   # edit
ansible-playbook -i inventory/hosts.yml playbooks/bootstrap-host.yml
```

---

## Related architecture

- [MVP vs Future](../architecture/MVP-AND-FUTURE-STATE.md)  
- [Device 802.1X](../architecture/device-8021x-eap-tls.md)  
- [Thin attestor](../architecture/thin-attestor.md)  
- [Entra request packets](../implementation/ENTRA_REQUESTS.md)  
