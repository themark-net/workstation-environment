# Import Jira

**Note (2026-08-07):** Create/adjust epics as:

| Epic | Scope |
|------|--------|
| LTZ-M0 | Foundations / lab MVP |
| LTZ-M1 | Device trust (attestor, agent, Intune artifacts) |
| LTZ-M2 | Tenant plug-in REQ-M* + CA compliant device |
| LTZ-F1 | Future CBA / FIDO |
| LTZ-F2 | Future AWX |
| LTZ-F3 | Future workload / SPIRE |

Do **not** title the MVP epic “TPM-CBA.” CBA belongs under **LTZ-F1**.

REQ catalog: [../../implementation/ENTRA_REQUESTS.md](../../implementation/ENTRA_REQUESTS.md).

### Network

Optional epic **LTZ-N1** / stories under **F3**: lab FreeRADIUS; production device EAP-TLS + RADIUS trust. Links: architecture `device-8021x-eap-tls.md`.
