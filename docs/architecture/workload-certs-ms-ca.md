# Architecture: MS CA Workload Intermediate & Service Identity

## Goal

Replace static tokens / shared secrets / over-privileged local accounts for **non-user** services on Linux clients and platform hosts with **enterprise PKI client certificates** under a dedicated **Workload intermediate**, managed by **AWX**.

## PKI layout

```text
Enterprise Root CA
├── Intermediate: User / CBA          → TPM user certs → Entra CBA
└── Intermediate: Workload / Device   → host & service certs → mTLS, APIs, 802.1X
         └── (optional) SPIRE signing intermediate
```

### Workload certificate profiles

| Profile | Identity | Lifetime | Key storage | Consumers |
|---------|----------|----------|-------------|-----------|
| Host | Machine FQDN / inventory ID | 60–90d | File (root) or TPM | Inventory, host-level APIs |
| Service | `service@host` or SAN URI | 30–60d | File owned by unit user | Per-agent mTLS |
| SPIRE Upstream | SPIRE server intermediate | per SPIRE design | HSM/server | SVID issuance |

## Relationship to systemd accounts

- **Keep** unprivileged `User=` / `DynamicUser=` for filesystem and capability isolation.
- **Stop** using local accounts as the network trust signal.
- **Stop** long-lived API keys in `/etc`.
- Harden units: `ProtectSystem=strict`, `ProtectHome=true`, `NoNewPrivileges=true`, `Credential=` / state dirs.

## AWX lifecycle

1. Ensure unit + OS user.
2. Generate key + CSR (TPM optional for high-value).
3. Enroll via SCEP/EST/ACME or enterprise enrollment API (PKI team interface).
4. Install cert; reload unit.
5. Renew on timer; alert < 14–30 days.
6. Publish status to trust agent → Intune compliance.

## Entra interaction

Workload certs are **not** Entra user CBA certs. Optional later: SPIRE JWT-SVID federated to Entra **application / managed identity** (workload identity federation)—separate access request from user CBA.

## Success criteria

- No static shared secrets for in-scope agents.
- Each semi-privileged client service runs non-root with unique unit identity.
- Certs auto-renew; expired cert → compliance fail within SLA.

---

## Device certificates and 802.1X

The **device intermediate** (or a sibling template under the same enterprise root) also issues **machine client certificates** for **802.1X EAP-TLS**.

| Consumer | Cert type | Plane |
|----------|-----------|--------|
| Compliance / attestor ticket | Device identity | D |
| **802.1X machine EAP-TLS** | Device client cert (EKU Client Auth) | D |
| Workload agents | Workload client cert | W |
| User CBA | User cert (Future) | H |

RADIUS trusts the **device** chain. Do not point 802.1X at user CBA certificates.  
Full design: [device-8021x-eap-tls.md](device-8021x-eap-tls.md) · runbook: [../runbooks/device-8021x-eap-tls.md](../runbooks/device-8021x-eap-tls.md).
