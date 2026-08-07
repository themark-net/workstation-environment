# Attestor client

The production agent embeds attest calls (`agent/ltz-trust-agent.sh`).

```http
POST {ATTESTor_URL}/v1/attest
Content-Type: application/json

{"device_id":"...","evidence":{"tpm_present":true,"ts":123,"nonce":"..."}}

→ 200 {"ticket":"...","expires_at":1234567890}
→ 403 {"error":"..."}
```

Configure `LTZ_ATTESTOR_URL` only — never hard-code lab hostnames in client code.
