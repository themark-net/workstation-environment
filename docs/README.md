# Workstation Environment — Documentation

Operational, architectural, and **delivery** docs for managed Linux workstations on the **same Entra / Intune / Conditional Access plane** as Windows—plus **workload identity** (MS CA intermediate, SPIRE) and **AWX** continuous policy.

## Start here

| Doc | Audience |
|-----|----------|
| [Executive proposal](executive/EXECUTIVE-PROPOSAL.md) | Leadership / funding |
| [Cost estimates (hours)](executive/COST-ESTIMATES.md) | PMO / Jira |
| [Implementation plan](implementation/IMPLEMENTATION-PLAN.md) | Delivery teams |
| [Entra access request catalog](implementation/entra-access-requests.md) | IAM / limited Entra access |
| [Agile import pack (Jira + GitLab)](project/README.md) | Scrum masters |

## Architecture

| Doc | Purpose |
|-----|---------|
| [Identity planes overview](architecture/identity-planes-overview.md) | Human / device / workload / management |
| [SPIFFE / SPIRE](architecture/spiffe-spire.md) | Workload plane; when not to use |
| [MS CA workload certs](architecture/workload-certs-ms-ca.md) | Non-user certs + systemd |

## Runbooks

| Doc | Purpose |
|-----|---------|
| [Linux Zero Trust with Entra](runbooks/linux-zero-trust-entra.md) | Master ZT runbook |
| [TPM CBA (no USB)](runbooks/tpm-cba-no-usb.md) | Required user passwordless path |
| [AWX GPO parity](runbooks/ansible-awx-gpo-parity.md) | Continuous Ansible + compliance |
| [Intune compliance bridge](runbooks/intune-compliance-bridge.md) | status.json → CA |

## Design principles

1. **One decision plane** — Entra + Intune + Conditional Access.
2. **No USB** for day-to-day Entra passwordless — platform TPM CBA.
3. **SSSD OIDC hybrid** remains for local/session identity (done).
4. **Goldimage** playbooks are the admin baseline (SSH, YubiKey)—consume, don’t fork.
5. **AWX (new OSS)** = GPO-class continuous enforce; stale = non-compliant.
6. **Workload intermediate** for agents; **SPIRE** for attested platform services.
7. **Limited Entra access** — formal Microsoft-termed requests only.

## Related repos (logical)

- goldimage — baseline SSH / YubiKey admin  
- customized SSSD hybrid — done  
- ansible-workstation-environment — ZT roles  
- awx-config / spire-infra — create under program  
