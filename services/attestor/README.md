# ltz-attestor (thin attestor service)

**Standalone service.** No dependency on `lab/`.

MVP: verify enrolled device + evidence → issue short-lived ticket.

## Run (dev)

```bash
python3 -m venv .venv && . .venv/bin/activate
pip install -r requirements.txt
export LTZ_ATTESTOR_TOKEN_TTL=3600
export LTZ_ATTESTOR_HMAC_SECRET=change-me-lab-only
python3 app.py
```
