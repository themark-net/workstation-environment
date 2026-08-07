# Runbook: Intune Linux Compliance Bridge

**Status:** MVP — attestor-backed  
**Last updated:** 2026-08-07

---

## Flow

```text
ltz-trust-agent → attestor ticket → status.json
Intune discovery.sh reads status.json
  → attested + ticket_fresh must be true
rules.json evaluates those booleans
→ Compliant bit → Conditional Access
```

Artifacts (upload as-is on plug-in day):

- `client/intune/discovery.sh`  
- `client/intune/rules.json`  

Lab uses **mock Intune** at collector `GET /v1/mock-intune` until tenant access exists.

Do not treat discovery script output as hardware proof without the **thin attestor** ticket.
