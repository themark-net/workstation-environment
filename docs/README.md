# Workstation Environment — Documentation

Operational and architectural docs for managed Linux workstations that join the **same Entra / Intune / Conditional Access control plane** as Windows.

## Runbooks

| Document | Purpose |
|----------|---------|
| [Linux Zero Trust with Entra (master)](runbooks/linux-zero-trust-entra.md) | Unified trust model, no parallel Linux IdP, funding narrative |
| [TPM-backed Entra CBA (no USB)](runbooks/tpm-cba-no-usb.md) | Required path: platform TPM via PKCS#11 + Entra certificate-based auth |
| [AWX policy plane & GPO parity](runbooks/ansible-awx-gpo-parity.md) | Ansible/AWX as continuous configuration + Intune as compliance truth |
| [Intune Linux compliance bridge](runbooks/intune-compliance-bridge.md) | Status agent, custom compliance, Conditional Access |

## Design principles

1. **One decision plane** — Entra (user auth strengths) + Intune (device compliant) + Conditional Access.
2. **No USB token required** — user Entra credentials are hardware-bound in the **platform TPM** (virtual smart card / CBA).
3. **Local login stays flexible** — SSSD OIDC (and existing Ansible auth roles) may remain separate from cloud CBA.
4. **OS management depth** — AWX Ansible is the GPO-class *enforcement* engine; Intune is the *compliance signal* Entra trusts.
5. **No parallel security island** — reuse enterprise PKI, Entra CBA, Intune, existing MDATP/Nessus deployments.

## Related repos

- [`ansible-workstation-environment`](https://github.com/themark-net/ansible-workstation-environment) — playbooks/roles
- This repo — architecture, runbooks, inventory patterns
