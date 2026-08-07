# Runbook: Workload MS CA Certificates

See architecture [../architecture/workload-certs-ms-ca.md](../architecture/workload-certs-ms-ca.md).

**Goal:** Enterprise client certs for non-user services under a workload intermediate; AWX-managed lifecycle.

---

## Related: device 802.1X

Machine network certs are plane **D**, attestor-gated. See [../architecture/device-8021x-eap-tls.md](../architecture/device-8021x-eap-tls.md) and [device-8021x-eap-tls.md](device-8021x-eap-tls.md).

Do **not** use user CBA templates for EAP-TLS machine auth.
