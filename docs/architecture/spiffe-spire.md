# Architecture: SPIFFE / SPIRE (Workload Plane)

## Role in the program

SPIRE issues short-lived **SPIFFE Verifiable Identity Documents (SVIDs)** to **workloads** after node + workload attestation. It does **not** replace Entra CBA, Intune, or SSSD OIDC.

| Use SPIRE | Do not use SPIRE for |
|-----------|----------------------|
| Service-to-service mTLS without static secrets | Human Entra login |
| Attested agents on managed nodes | Device compliance bit |
| JWT-SVID → Entra **workload identity federation** (later) | Conditional Access user grants |
| High-churn services across K8s/VMs | Replacing systemd UIDs |

## Target topology (initial)

```text
                    ┌─────────────────────┐
                    │ SPIRE Server (HA)   │
                    │ Trust domain:       │
                    │ spiffe://corp.example│
                    │ UpstreamAuthority:  │
                    │ MS CA Workload int. │
                    └──────────┬──────────┘
                               │
              ┌────────────────┼────────────────┐
              ▼                ▼                ▼
        SPIRE Agent      SPIRE Agent      SPIRE Agent
        (AWX node)       (Linux WS)       (optional k8s)
              │                │
              ▼                ▼
        Workload SVIDs   trust-agent / platform agents
```

**Phase 1:** Deploy SPIRE for **platform** (AWX execution nodes, internal agents, future services).  
**Phase 2:** Optional SPIRE agents on workstation fleet only where multi-service attestation is required; default client agents may use **MS CA client certs via AWX** without SPIRE.

## Upstream CA

- Prefer **MS CA Workload Intermediate** as SPIRE `UpstreamAuthority` (disk/API integration as designed with PKI team).
- SPIRE intermediate under workload intermediate; SVIDs chain to enterprise root.
- Do **not** use User/CBA intermediate or Entra CBA trust store as SPIRE issuer.

## Registration policy (examples)

| Selector | SPIFFE ID pattern |
|----------|-------------------|
| systemd unit `org-trust-agent.service` | `spiffe://corp.example/ws/trust-agent` |
| AWX EE / receptor | `spiffe://corp.example/platform/awx-ee` |
| Custom agent | `spiffe://corp.example/ws/<agent-name>` |

## Ops ownership

- **Platform team:** SPIRE server HA, backups, trust bundle distribution.
- **AWX:** Deploy/upgrade agents via playbook from goldimage patterns.
- **Security:** Registration policies, trust domain name, federation approvals.

## Out of scope (v1)

- Replacing admin YubiKey SSH (goldimage) with SPIRE.
- Desktop interactive login via SVID.
- Full mesh on every laptop.

---

## Not for 802.1X

SPIRE SVIDs are **workload** identities. **802.1X machine EAP-TLS** uses classic **device X.509 client certs** (attestor + enterprise CA), not SPIFFE IDs. Keep RADIUS on the device CA path. See [device-8021x-eap-tls.md](device-8021x-eap-tls.md).
