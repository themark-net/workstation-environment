# Thin Attestor (Device Trust)

**Status:** Strengthened MVP — challenge/response + pluggable backends  
**Last updated:** 2026-08-09

---

## 1. Role

Remote service that:

1. Issues a **challenge** (nonce) bound to an enrolled device.  
2. Accepts **evidence** that binds that nonce (HMAC; optional TPM quote metadata).  
3. Verifies evidence via a **pluggable backend** (`local` or `maa`).  
4. On success, mints a **short-lived ticket**.  
5. On failure, returns deny — no credential.

Downstream agents and Intune discovery trust **tickets / status derived from tickets**, not raw unauthenticated local claims.

**Clients never call MAA.** They only call this attestor. Swapping backends is a **server deploy** change.

---

## 2. Stable client contract (v2)

```text
POST /v1/enroll
  { device_id, join_token, meta? }
  → 201 { device_id, device_secret, status }   # store device_secret 0600

POST /v1/challenge
  { device_id }
  → 200 { challenge_id, nonce, expires_at }

POST /v1/attest
  { device_id, challenge_id, evidence }
  → 200 { ticket, expires_at, backend, verification }

POST /v1/verify_ticket
  { ticket } → { valid, device_id }

GET  /healthz  → { status, backend }
GET  /v1/meta  → capability advertisement
```

### Evidence (`hmac_v1`)

```text
proof_hmac = HMAC-SHA256(device_secret,
  "ltz-evidence-v1|{device_id}|{challenge_id}|{nonce}|{ts}|{0|1}|{hostname}")
```

Fields: `scheme`, `challenge_id`, `nonce`, `ts`, `tpm_present`, `hostname`, `proof_hmac`, optional `tpm_quote`.

Agent implementation: `client/agent/ltz-trust-agent.sh` (copied into Ansible role files).

---

## 3. Backends (server-side only)

| `LTZ_ATTESTOR_BACKEND` | Behavior |
|------------------------|----------|
| **`local`** (default) | Challenge nonce + device HMAC; optional quote nonce binding; STRICT_TPM for presence |
| **`maa`** | Plug-in for Microsoft Azure Attestation (needs Azure subscription + endpoint/token — **not** in M365 E3) |

Code: `services/attestor/backends/{local,maa,base}.py`.

### Enabling MAA later

1. Create Azure Attestation provider + obtain API auth.  
2. Set on attestor host:
   ```bash
   LTZ_ATTESTOR_BACKEND=maa
   LTZ_MAA_ENDPOINT=https://<provider>.<region>.attest.azure.net
   LTZ_MAA_BEARER_TOKEN=...
   # optional hybrid: LTZ_MAA_ALSO_LOCAL=1
   ```
3. Complete `backends/maa.py` JWT/JWKS validation (stub documents the hook).  
4. **Do not change agents** if evidence envelope stays the same (or add `maa_token` field later).

---

## 4. Policy (lab defaults)

| Check | local backend |
|-------|----------------|
| Device enrolled + `device_secret` | Required |
| Challenge unexpired + nonce match | Required |
| Evidence HMAC | Required (`LTZ_ATTESTOR_REQUIRE_HMAC=1`) |
| Timestamp skew | ≤ 600s |
| TPM present | If `LTZ_ATTESTOR_STRICT_TPM=1` |
| Full AK quote crypto | Optional / next hardening |

---

## 5. Code locations

| Piece | Path |
|-------|------|
| Service | `services/attestor/` |
| Backends | `services/attestor/backends/` |
| Agent | `client/agent/ltz-trust-agent.sh` |
| Lab deploy | `lab/ansible/roles/lab_attestor/` |

---

## 6. Trust narrative

```text
Device ──challenge/evidence──► Thin Attestor ──verify──► backend (local | MAA)
                                      │
                                      └── ticket ──► agent status.json ──► Intune discovery
                                                      collector / RP
```

Intune custom compliance remains a **presentation channel**. Root of trust is the attestor ticket after backend verification.
