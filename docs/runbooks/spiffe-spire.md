# Runbook: SPIFFE / SPIRE in the Zero Trust Program

**Status:** Architecture / phased adoption  
**Last updated:** 2026-08-05  

---

## 1. Decision summary

| Question | Answer |
|----------|--------|
| Replace Entra CBA / Intune for laptops? | **No** |
| Required for Phase 1 desktop acceptance? | **No** |
| Useful with new AWX + workload MS CA intermediate? | **Yes — Phase 2+** for non-human / service identity |
| Use MS CA as upstream? | **Yes** — workload intermediate as SPIRE `UpstreamAuthority` (or shared root hierarchy) |

---

## 2. Planes (do not merge)

```text
Human + device  → Entra CBA (TPM) + Intune + CA     [Phase 1]
Service / agent → Workload certs (MS CA)             [Phase 1b]
Service fabric  → SPIRE SVIDs (optional SPIRE)       [Phase 2]
Federation      → JWT-SVID → Entra workload ID        [Phase 3 optional]
```

---

## 3. Target SPIRE topology (new deployment)

Assumptions: **new open-source AWX**; SPIRE infra deployed alongside automation platform (not on every laptop day one).

```text
SPIRE Server (HA pair)  — trust domain: spiffe://<org-domain>
  UpstreamAuthority: enterprise workload intermediate (or nested root SPIRE)
  Datastore: postgres (shared for HA)
  OIDC Discovery Provider (optional, for Entra workload federation)

SPIRE Agent
  — on Linux servers / k8s nodes first
  — on workstations only if host runs attested multi-service agents

Node attestation: join token / X509 / TPM (as available)
Workload attestation: systemd, unix, k8s (as applicable)
```

Deploy SPIRE Server/Agent configs **via AWX** from git; goldimage repo remains admin SSH/YubiKey baseline only.

---

## 4. Relation to local systemd accounts

SPIRE issues **SVIDs** to workloads after attestation. It does **not** remove the need for unprivileged OS users. Pattern:

1. Harden units (gold + systemd_hardening pack).  
2. Issue MS CA certs **or** SVIDs for off-box auth.  
3. Retire static tokens.  
4. Optionally migrate from MS CA long-lived agent certs → short-lived SVIDs.

---

## 5. Entra interaction

| Direction | Use |
|-----------|-----|
| SPIRE → Entra | JWT-SVID + **workload identity federation** (app registration) — non-human Azure/Graph access |
| Entra → SPIRE | Not used as CA for SVIDs |
| User CBA | Unrelated plane |

Requires a **dedicated Entra application / federated credential** request (see [ENTRA_REQUESTS.md](../implementation/ENTRA_REQUESTS.md)).

---

## 6. When to start SPIRE work

Start Phase 2 SPIRE when **any** of:

- Multiple internal services need mTLS without per-service CSR churn  
- K8s / multi-node agents need secret-less identity  
- Compliance demands attested workload identity beyond “Ansible installed a cert”

Until then, MS CA workload intermediate + AWX is sufficient for client agents.

---

## 7. Related

- [workload-certs-ms-ca.md](workload-certs-ms-ca.md)  
- [linux-zero-trust-entra.md](linux-zero-trust-entra.md)  
