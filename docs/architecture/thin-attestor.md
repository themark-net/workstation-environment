# Thin Attestor (MVP Device Trust)

**Status:** MVP critical component (ticket + optional device cert for 802.1X)  
**Last updated:** 2026-08-07

---

## 1. Role

Remote service that:

1. Accepts **device evidence** (TPM/vTPM quote and/or signed health bundle).  
2. Evaluates **policy** (device enrolled, evidence fresh, required claims).  
3. On success, mints a **short-lived device ticket or client certificate**.  
4. On failure, returns deny — no credential.

Downstream compliance agent and relying parties **trust the attestor**, not raw local `status.json` alone.

---

## 2. MVP policy (lab-default)

| Check | MVP |
|-------|-----|
| Device id registered (birth record) | Required |
| Evidence timestamp / nonce freshness | Required |
| TPM/vTPM present (or lab soft-key mode flag) | Required in strict mode |
| Optional PCR allowlist | Future / optional |
| MAA JWT verification | Future optional backend |

---

## 3. Interfaces

```text
POST /v1/attest
  body: { device_id, evidence, nonce }
  → 200 { ticket, expires_at, device_cert? } | 403
  device_cert (when ISSUE_DEVICE_CERT=1):
    { certificate_pem, private_key_pem, ca_pem, expires_at }

GET /v1/device_ca
  → 200 { ca_pem }  # for RADIUS / clients when cert issuance enabled

POST /v1/enroll  (lab; prod may be Intune-only for device object)
  body: { device_id, pubkey, join_token }
  → 201 birth record
```

Ticket is presented by the agent to **collector** and optionally used as TLS client cert material depending on deployment mode.

**Network (802.1X):** The same successful attest can authorize minting/renewal of a **device client certificate** for EAP-TLS (machine auth). RADIUS trusts the device CA chain. User CBA certificates must not be used for 802.1X. See [device-8021x-eap-tls.md](device-8021x-eap-tls.md).

---

## 4. Code locations

| Piece | Path |
|-------|------|
| Service (standalone) | [services/attestor/](../../services/attestor/) |
| Host client | [client/attestor-client/](../../client/attestor-client/) |
| Lab deploy of service | [lab/ansible/roles/lab_attestor/](../../lab/ansible/roles/lab_attestor/) |

---

## 5. Prod swap

| Lab | Production |
|-----|------------|
| step-ca / file CA | Enterprise MS CA or internal cert API |
| In-memory device registry | DB + inventory allowlist |
| Optional soft evidence | Discrete TPM quotes; optional MAA |

Client and service **config** change; **protocol** stays stable.

## Device certificates (MVP 802.1X)

When `LTZ_ATTESTOR_ISSUE_DEVICE_CERT=1`, successful `/v1/attest` also returns a short-lived **device client certificate** (Client Auth EKU) for machine EAP-TLS. See [device-8021x-eap-tls.md](device-8021x-eap-tls.md).
