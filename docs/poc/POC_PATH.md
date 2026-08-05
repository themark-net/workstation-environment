# Offline / Pre-Tenant Proof of Concept Path

**Status:** Lab validation guide  
**Last updated:** 2026-08-05  
**Audience:** Linux platform engineers validating LTZ components before tenant integration  

This document describes a **self-contained proof of concept (POC)** that exercises the technical building blocks of the Linux Zero Trust program **without requiring changes to Microsoft Entra, Intune tenant policy, or production PKI**.

Tenant integration (Entra CBA, Intune custom compliance, Conditional Access) is documented separately in [ENTRA_REQUESTS.md](../implementation/ENTRA_REQUESTS.md) and production runbooks. The POC proves the **client and automation stack** so tenant enablement is configuration, not research.

**Lab deploy:** [../../lab/README.md](../../lab/README.md) (Proxmox + Ansible; optional Docker subset).

---

## 1. Objectives

| ID | Objective | Success signal |
|----|-----------|----------------|
| P1 | Non-exportable key in TPM (or vTPM) | Sign op requires PIN; no PEM private key on disk |
| P2 | Certificate-based client auth UX (no USB) | Browser or curl mTLS to lab RP succeeds with TPM-backed cert |
| P3 | Continuous desired-state config | Timer/AWX reapplies config; `policy_gen` increments |
| P4 | Fail-closed health gate | Bad/missing `status.json` blocks access to lab protected API |
| P5 | Workload identity without static tokens | Two services mTLS with lab-issued certs only |
| P6 | Optional SPIRE | Short-lived SVID issued to a lab workload |
| P7 | Non-regression | Existing local auth flows on the lab image still work |

Out of scope for this POC: live Entra CBA, live Intune compliance bit, production CA enrollment.

---

## 2. Architecture

```text
                    ┌─────────────────┐
                    │  lab-ca         │
                    │  step-ca /      │
                    │  root+intermed  │
                    └────────┬────────┘
           user-sim │        │ workload
                    │        │
         ┌──────────▼──┐  ┌──▼────────────┐
         │ lab-ws1     │  │ lab-svc-a/b   │
         │ vTPM        │  │ mTLS services │
         │ trust-agent │  └───────┬───────┘
         │ policy timer│          │
         └──────┬──────┘          │
                │ client cert     │
         ┌──────▼─────────────────▼──┐
         │ lab-rp (nginx mTLS)       │
         │ + compliance gate API     │
         └───────────────────────────┘
                │ optional
         ┌──────▼──────┐
         │ lab-spire   │
         └─────────────┘
```

| VM / role | Purpose |
|-----------|---------|
| **lab-ca** | Lab root + intermediates (`user-cba-sim`, `workload`) |
| **lab-rp** | Relying party: mTLS + optional status gate |
| **lab-ws\*** | Workstation: vTPM, tpm2-pkcs11, trust-agent, policy pull |
| **lab-svc-a/b** | Workload mTLS demo |
| **lab-spire** | Optional SPIRE server |
| **lab-awx** | Optional; default POC uses `ansible-pull` / local ansible |

---

## 3. Mapping POC → production

| POC component | Production counterpart |
|---------------|------------------------|
| Lab CA user intermediate | Enterprise user/CBA template + Entra CBA trust |
| nginx mTLS RP | Entra certificate-based authentication |
| `status.json` + local gate | Intune custom compliance + Conditional Access |
| ansible-pull / mini-AWX | Org AWX continuous enforce |
| Lab workload intermediate | MS CA workload intermediate |
| SPIRE lab trust domain | Prod SPIRE (+ optional Entra workload federation) |
| vTPM | Platform TPM 2.0 on physical hardware |

---

## 4. Phased validation checklist

### Phase A — Crypto & CBA-shaped auth (P1, P2)

- [ ] vTPM visible (`/dev/tpm0` or `/dev/tpmrm0`)
- [ ] tpm2-pkcs11 token created; key generated **in** TPM
- [ ] CSR signed by lab `user-cba-sim` intermediate
- [ ] Certificate imported to token; NSS or p11-kit configured
- [ ] HTTPS to `lab-rp` with client cert succeeds
- [ ] Request without cert or wrong CA fails

### Phase B — Agent & continuous config (P3, P4)

- [ ] `org-trust-agent` timer writes `/var/lib/org-trust/status.json`
- [ ] Policy role applies managed files; `policy_gen` updates
- [ ] Intentional drift self-heals within interval
- [ ] Gate denies when `ts` stale or `tpm_cba_cert` false
- [ ] Gate allows when status healthy

### Phase C — Workload certs (P5)

- [ ] Services use certs from `workload` intermediate only
- [ ] Static shared secret removed from demo config
- [ ] Unprivileged systemd user / DynamicUser where applicable

### Phase D — SPIRE optional (P6)

- [ ] SPIRE server healthy; agent attested
- [ ] X.509-SVID fetched; mTLS or file-based verify

### Phase E — Evidence pack

Capture under `lab/evidence/` (gitignored samples only in repo):

- Command logs for TPM key + cert list  
- curl verbose mTLS success/failure  
- status.json samples (healthy / failed)  
- Policy apply logs  

---

## 5. Effort guide (single engineer, LLM-assisted)

| Package | Hours (approx.) |
|---------|----------------:|
| Lab infra up (Proxmox TF + base OS) | 8–16 |
| Phase A | 15–25 |
| Phase B | 10–20 |
| Phase C | 10–20 |
| Phase D (optional) | 20–40 |
| Evidence polish | 5–10 |
| **Without SPIRE** | **~60–80** |
| **With SPIRE** | **~80–120** |

---

## 6. Explicit non-goals

- No dependency on new Entra app registrations for the lab path  
- No production CRL or corp CA enrollment required  
- No claim of production Conditional Access parity until tenant integration  
- Lab hostnames and DNs use `lab.ltz.local` (or configured lab domain) only  

---

## 7. Related

- [lab/README.md](../../lab/README.md) — deploy  
- [tpm-cba-no-usb.md](../runbooks/tpm-cba-no-usb.md) — production path  
- [intune-compliance-bridge.md](../runbooks/intune-compliance-bridge.md)  
- [workload-certs-ms-ca.md](../runbooks/workload-certs-ms-ca.md)  
- [spiffe-spire.md](../runbooks/spiffe-spire.md)  
