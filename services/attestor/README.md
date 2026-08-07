# ltz-attestor

Thin attestor service for LTZ **device trust MVP**.

## API

| Endpoint | Purpose |
|----------|---------|
| `GET /healthz` | Liveness |
| `POST /v1/enroll` | Birth record (`device_id`, `join_token`) |
| `POST /v1/attest` | Evidence → short-lived ticket (+ optional **device client cert**) |
| `POST /v1/verify_ticket` | Ticket validation for collector/RP |
| `GET /v1/device_ca` | Publish device CA PEM (when cert issuance enabled) |

## Device cert (MVP 802.1X)

Set `LTZ_ATTESTOR_ISSUE_DEVICE_CERT=1` to mint a short-lived **device** client certificate on successful attest. RADIUS (lab FreeRADIUS / prod NPS) trusts the published device CA. Same posture gate as the compliance ticket — not a parallel PKI.

Env:

| Variable | Default | Meaning |
|----------|---------|---------|
| `LTZ_ATTESTOR_ISSUE_DEVICE_CERT` | `0` | Enable device cert mint |
| `LTZ_ATTESTOR_DEVICE_CA_DIR` | `/var/lib/ltz-attestor/device-ca` | CA material |
| `LTZ_ATTESTOR_CERT_TTL` | same as ticket TTL | Target cert lifetime (openssl days ceil) |
| `LTZ_ATTESTOR_TOKEN_TTL` | `3600` | Ticket lifetime seconds |

## Standalone

```bash
pip install -r requirements.txt
export LTZ_ATTESTOR_ISSUE_DEVICE_CERT=1
python app.py
```

No dependency on `lab/`.
