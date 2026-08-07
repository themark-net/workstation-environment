# Runbook: Workload Certificates (MS CA Intermediate) for Non-User Services

**Status:** Architecture / implementation  
**Last updated:** 2026-08-07  
**Depends on:** Enterprise PKI, new AWX instance, gold baseline playbooks  

---

## 1. Purpose

Issue and renew **non-user** certificates from a dedicated **Microsoft enterprise CA intermediate** for services and agents on managed Linux clients (and later servers). Goal: replace static API keys / shared secrets and reduce reliance on semi-privileged local accounts as *network* trust.

Human Entra CBA (TPM) remains a **separate** intermediate/template family — see [tpm-cba-no-usb.md](tpm-cba-no-usb.md).

---

## 2. PKI layout

```text
Enterprise Root CA
├── Intermediate: User / CBA          → TPM user certs → Entra CBA
└── Intermediate: Workload / Device   → host & service certs → mTLS, internal APIs
```

| Property | Workload intermediate |
|----------|----------------------|
| EKU | Client Authentication (and Server Auth only if needed) |
| Lifetime | 30–90 days (prefer 30–45 for agents) |
| Key | RSA 2048+ or org standard; TPM optional for high-value agents |
| Subject models | Host CN/SAN **or** service CN + machine binding |
| CRL/AIA | HTTP reachable by relying parties |

**Do not** share user-CBA certificate templates with workload issuance.

---

## 3. OS principal vs cryptographic identity

| Layer | Mechanism | Role |
|-------|-----------|------|
| OS | `systemd` `User=` / `DynamicUser=` | Filesystem, cgroup, capabilities |
| Crypto | Workload cert (this doc) or SPIRE SVID | Off-box auth, mTLS |

Local systemd accounts **stay** for isolation. Certs **replace secrets and implicit network trust**.

---

## 4. AWX policy packs

| Pack | Responsibility |
|------|----------------|
| `workload_ca_trust` | Install workload intermediate + root chain |
| `workload_certs` | CSR/enroll/renew, install under `/var/lib/org-workload/<svc>/` |
| `systemd_hardening` | Non-root units, `ProtectSystem`, `LoadCredential` |
| `trust_agent` | Report cert presence/expiry into status.json |

Enrollment options (pick during WP): SCEP, EST, REST to CA/NDE, or ACME if available. Gold image repo owns baseline SSH/YubiKey; this pack is layered by the new AWX.

---

## 5. Service target state (client)

```text
unit: org-trust-agent.service
  User=org-trust (or DynamicUser)
  LoadCredential= or cert path root-owned, service-readable
  mTLS to internal endpoints with workload cert

unit: custom-agent / log-shipper / etc.
  same pattern; unique cert or host cert + SPIFFE later
```

---

## 6. Compliance hook

`status.json` fields (see [intune-compliance-bridge.md](intune-compliance-bridge.md)):

- `workload_cert_present`
- `workload_cert_not_after`
- Fail if missing or < 14 days remaining (tune)

---

## 7. Related

- [spiffe-spire.md](spiffe-spire.md) — when to add SPIRE atop this intermediate  
- [ansible-awx-gpo-parity.md](ansible-awx-gpo-parity.md)

---

## Related: device 802.1X

Machine network certs are plane **D**, attestor-gated. See [../architecture/device-8021x-eap-tls.md](../architecture/device-8021x-eap-tls.md) and [device-8021x-eap-tls.md](device-8021x-eap-tls.md).
