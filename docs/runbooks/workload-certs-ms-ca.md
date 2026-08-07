# Runbook: Workload Certificates (MS CA Intermediate)

**Status:** Future (F3)  
**Last updated:** 2026-08-07

Issue **service/host client certificates** under a **Workload / Device intermediate**. Managed by AWX enrollment/renewal roles. Not Entra user CBA.

See architecture: [../architecture/workload-certs-ms-ca.md](../architecture/workload-certs-ms-ca.md).

## Checklist

1. Agree intermediate template with PKI (EKU Client Auth; SAN conventions).  
2. AWX role: CSR → enroll → install → timer renew.  
3. Retire static secrets for in-scope agents.  
4. Optional: SPIRE UpstreamAuthority under same intermediate.

---

## Related: device certs for 802.1X

Machine EAP-TLS uses **device** client certs from the same PKI family (device intermediate / template with Client Auth EKU). Coordinate template names with network (RADIUS trust list). See [device-8021x-eap-tls.md](device-8021x-eap-tls.md).
