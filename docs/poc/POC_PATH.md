# Offline / Pre-Tenant Proof of Concept Path

**Status:** Lab validation guide  
**Last updated:** 2026-08-07  
**Audience:** Linux platform engineers validating LTZ components before tenant integration  

Self-contained POC of Linux Zero Trust **device** building blocks **without** new Entra/Intune tenant changes or production PKI. Tenant integration remains [ENTRA_REQUESTS.md](../implementation/ENTRA_REQUESTS.md).

**Aligned to:** compliance-first MVP (attestor + compliance). CBA is not on the POC critical path.  
**Lab deploy:** [../../lab/README.md](../../lab/README.md).

---

## 1. Objectives

| ID | Objective | Success signal |
|----|-----------|----------------|
| P1 | Non-exportable key in TPM (or vTPM) | Sign requires PIN; no PEM private key on disk |
| P2 | Device/client cert auth (no USB) | mTLS to lab RP with TPM-backed or lab-issued device cert |
| P3 | Continuous desired-state config | Timer/Ansible reapplies; policy_gen increments |
| P4 | Fail-closed health gate | Bad/missing status.json blocks protected API |
| P5 | Workload identity without static tokens | Services mTLS with lab-issued certs only |
| P6 | Optional SPIRE | Short-lived SVID to a lab workload |
| P7 | Non-regression | Existing local auth on lab image still works |
| P8 | Optional 802.1X | Machine EAP-TLS with device cert against lab RADIUS |

Out of scope: live Entra CBA, live Intune Compliant bit, production CA enrollment.

---

## 2. Architecture (lab)

```text
lab-ca (step-ca) ──► lab-ws (vTPM, trust-agent, attestor client)
                 ──► lab-rp (mTLS + compliance gate)
                 ──► lab-svc-a/b (workload mTLS)
                 ──► lab-radius (optional 802.1X)
                 ──► lab-spire (optional)
```

---

## 3. Mapping POC → production

| POC | Production |
|-----|------------|
| Lab CA + attestor ticket/cert | Thin attestor + enterprise device intermediate |
| status.json + local gate | Intune custom compliance + CA compliant device |
| ansible-pull | Org AWX continuous enforce |
| Lab RADIUS EAP-TLS | Corp RADIUS + device 802.1X |
| SPIRE lab | Prod SPIRE (optional) |

---

## 4. Phased validation checklist

### Phase A — Device crypto & cert

- [ ] vTPM or TPM visible  
- [ ] Attestor enroll + attest → short-lived ticket/cert  
- [ ] mTLS to lab-rp succeeds with device cert; fails without  

### Phase B — Agent & continuous config

- [ ] Trust agent writes status.json  
- [ ] Policy drift self-heals  
- [ ] Gate denies stale/unhealthy status  

### Phase C — Workload certs

- [ ] Services use workload intermediate only  
- [ ] No static shared secrets in demo  

### Phase D — SPIRE optional

- [ ] Server healthy; agent attested; SVID usable  

### Phase E — 802.1X optional

- [ ] Device client cert only after successful attest  
- [ ] wpa_supplicant/NM EAP-TLS vs FreeRADIUS  
- [ ] Reject without cert; accept with valid cert; reject after expiry without renew  

See [../architecture/device-8021x-eap-tls.md](../architecture/device-8021x-eap-tls.md).

### Phase F — Evidence pack

Capture under `lab/evidence/` (gitignored samples): attestor logs, mTLS curls, status.json healthy/fail, RADIUS accept/reject if Phase E run.

---

## 5. Effort guide (single engineer, LLM-assisted)

| Package | Hours (approx.) |
|---------|----------------:|
| Lab infra | 8–16 |
| Core A–C | 35–65 |
| SPIRE optional | 20–40 |
| 802.1X optional | 8–16 |
| Evidence | 5–10 |
| **Core without SPIRE/802.1X** | **~50–90** |

---

## 6. Explicit non-goals

- No new Entra app registrations for the lab path  
- No production CRL or corp CA enrollment required  
- No claim of production Conditional Access parity until tenant integration  

---

## 7. Related

- [lab/README.md](../../lab/README.md)  
- [../architecture/device-8021x-eap-tls.md](../architecture/device-8021x-eap-tls.md)  
- [intune-compliance-bridge.md](../runbooks/intune-compliance-bridge.md)  
- [device-8021x-eap-tls.md](../runbooks/device-8021x-eap-tls.md)  
- [workload-certs-ms-ca.md](../runbooks/workload-certs-ms-ca.md)  
