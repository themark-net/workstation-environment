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

---

## Relation to 802.1X

Intune **Compliant** gates **cloud** Conditional Access. **802.1X** gates **LAN** access using the same attestor-backed **device cert**. A host can fail closed on the wire without a valid cert even if cloud policies differ. Do not conflate user CBA certs with machine EAP-TLS. See [device-8021x-eap-tls.md](device-8021x-eap-tls.md).
