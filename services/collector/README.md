# ltz-collector

Accepts compliance reports **only** with a valid attestor ticket.  
Includes an in-memory **mock Intune sink** for lab/demo.

```bash
pip install -r requirements.txt
export LTZ_ATTESTOR_VERIFY_URL=http://127.0.0.1:8443/v1/verify_ticket
python3 app.py
```
