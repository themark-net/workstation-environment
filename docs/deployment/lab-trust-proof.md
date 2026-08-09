# Lab trust proof — air-gapped components

**Purpose:** Document what the lab proves, how to re-run evidence, and which production component each piece maps to.  
**Audience:** Engineers handing off from Proxmox lab to Microsoft dev/demo.

---

## 1. Lab topology (typical)

| Role | Inventory group | Example IP | Function |
|------|-----------------|------------|----------|
| Device CA + cert mint | `lab_ca` | 10.42.0.57 | step-ca + `ltz-cert-mint :8445` |
| Relying party | `lab_rp` | 10.42.0.146 | Thin attestor :8443, collector :8089, FreeRADIUS |
| Workstation | `lab_workstations` | 10.42.0.52 | GUI + Intune path + agent + device cert |
| Server | `lab_servers` | 10.42.0.239 / .218 | Headless agent + device cert (no Intune stack) |
| SPIRE (optional) | `lab_spire` | — | Out of MVP critical path |

Air-gap means: no dependency on Entra for **device ticket issuance**. Intune enrollment still needs Microsoft cloud when you demonstrate the **presentation** path on ws1.

---

## 2. Trust chain under test

```text
[Host agent]
    │  POST /v1/attest  (+ challenge/HMAC or MAA backend on server)
    ▼
[Thin attestor] ── ticket (short TTL) ──► status.json / collector / Intune discovery
    │
    │  ticket in X-LTZ-Ticket + CSR
    ▼
[Cert mint] ── verifies ticket via attestor /v1/verify_ticket
    │  step ca sign (private key never leaves host)
    ▼
[Device client cert] ── EAP-TLS ──► [FreeRADIUS]
                                      trusts lab intermediate+root only
                                      never sees HMAC ticket
```

### What succeeds in lab

| Proof | How | Pass criteria |
|-------|-----|---------------|
| Attestor health | `curl http://$RP:8443/healthz` | 200 |
| Workstation ticket | `make demo-paths` or read `/var/lib/ltz-trust/status.json` | `attested=true`, fresh ticket |
| Server ticket | same on `lab_servers` | same without Intune packages |
| Cert mint gate | POST sign **without** ticket | 403 |
| Cert mint success | `ltz-request-device-cert` after agent | cert under `/var/lib/ltz-trust/pki/` |
| RADIUS server identity | `openssl verify -CAfile lab-ca-bundle.pem server.crt` | OK |
| EAP-TLS | `eapol_test` in `make ansible-8021x` | line contains `SUCCESS` |
| Intune presentation | enroll ws1; custom compliance | Compliant when ticket fresh |

---

## 3. One-shot redeploy

```bash
cd lab
make ansible-site-full
# or stepwise:
make ansible-bootstrap
make ansible-mvp
make ansible-8021x
make validate
make demo-paths
```

`ansible-8021x` is designed to be **idempotent and complete**:

1. Init/export step-ca (root + intermediate + **CA-signed RADIUS server cert**)
2. FreeRADIUS with absolute TLS paths and lab CA client trust
3. Install `/etc/ltz-trust/lab-ca-bundle.pem` on device hosts
4. Request device certs via client role `ltz_device_cert`
5. `eapol_test` smoke (must print SUCCESS)

Artifacts on controller (gitignored secrets under `lab/artifacts/`):

| File | Use |
|------|-----|
| `root_ca.crt` | Lab root |
| `intermediate_ca.crt` | Issuing CA for device + RADIUS server certs |
| `lab-ca-bundle.pem` | intermediate+root — client `ca_cert` for RADIUS **server** verify |
| `radius-server.crt` / `.key` | Installed on FreeRADIUS |

---

## 4. Evidence commands (copy into run notes)

Run from a host that can SSH as `ltz` (or use Ansible ad-hoc).

```bash
RP=10.42.0.146
CA=10.42.0.57
WS=10.42.0.52

# Attestor
curl -fsS "http://$RP:8443/healthz"

# Ticket / status on workstation
ssh ltz@$WS 'sudo cat /var/lib/ltz-trust/status.json | jq .'

# Cert mint health + negative test
curl -fsS "http://$CA:8445/healthz"
curl -sS -X POST "http://$CA:8445/v1/sign" -H 'Content-Type: application/pkcs10' -d 'not-a-csr' | jq .

# Device material
ssh ltz@$WS 'sudo openssl x509 -in /var/lib/ltz-trust/pki/device.crt -noout -subject -issuer -dates'

# EAP-TLS
ssh ltz@$WS 'sudo eapol_test -c /var/lib/ltz-trust/pki/eapol_test.conf -a '"$RP"' -s labradius -r 1 -t 10 | tail -20'
```

Record stdout (or attach `lab/evidence/`) for demo handoff.

---

## 5. Lab → production mapping

| Lab component | Proves | Production / Microsoft substitute |
|---------------|--------|-----------------------------------|
| Thin attestor (`local` backend) | Posture gate + ticket | Same `services/attestor`; optional `LTZ_ATTESTOR_BACKEND=maa` |
| Collector | Ticket-gated status sink | Same service or SIEM hook |
| step-ca + cert-mint | Ticket-gated device client certs | Cloud PKI / enterprise CA + mint API with same ticket gate |
| FreeRADIUS | Machine EAP-TLS trusts **device CA** | NPS / corp RADIUS; trust same device issuing CA |
| `ltz_trust_agent` | Host loop | Unchanged client role |
| `ltz_device_cert` | CSR + ticket → files for EAP | Unchanged; point `ltz_cert_mint_url` |
| `ltz_intune_prereqs` | GUI enroll path | Unchanged |
| `client/intune/*` | Compliant bit from ticket | Upload in tenant; assign pilot |
| Proxmox / air-gap | Isolated control of trust | N/A — replace with real network + tenant |

---

## 6. Explicit non-goals of the lab path

- **Not** proving Entra CBA (user plane)  
- **Not** requiring MAA for green lab (local HMAC is enough; MAA is a backend swap)  
- **Not** physical switch NAS (RADIUS ready at lab RP IP for later NAS config)  
- **Not** Cloud PKI product SKUs in air-gap  

Those land in [microsoft-path.md](microsoft-path.md) and [entra-azure-checklist.md](entra-azure-checklist.md).

---

## 7. Failure isolation

| Symptom | Likely plane | Check |
|---------|--------------|-------|
| No ticket / attested false | Attestor / agent | agent logs, TPM flag, attestor health |
| Cert mint 403 | Ticket expired / verify URL | re-run agent; mint `LTZ_ATTESTOR_VERIFY_URL` |
| Cert mint 500 step sign | step-ca down / provisioner | `systemctl status step-ca` |
| eapol FAIL / TLS alert | RADIUS server cert or client ca.pem | server must be CA-signed; client must use **bundle** not leaf-only |
| Intune non-compliant | Discovery / policy assign | status.json path; rules.json; pilot assignment |

---

## 8. Sign-off checklist

- [ ] `make ansible-mvp` green dual path  
- [ ] `make ansible-8021x` eapol SUCCESS on workstation **and** at least one server  
- [ ] Negative: mint without ticket → deny  
- [ ] Intune pilot device Compliant (if demonstrating Microsoft presentation)  
- [ ] This proof attached or linked in handoff notes  
