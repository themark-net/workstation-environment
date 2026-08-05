# Workstation Environment

Ansible-based setup for uniform Linux workstation/desktop environments that participate in the **same Microsoft Entra / Intune / Conditional Access Zero Trust plane** as Windows.

## Supported

- RHEL-based: Rocky, Alma, RHEL
- Debian-based: Ubuntu, Debian, Mint, Pop!_OS, Zorin
- Basic support for non-systemd (limited)

## Features (base playbook)

- Core tools: screen, vim, dev suite
- Unlimited bash history
- Podman + K8s tools
- Ceph client
- Modern sysadmin CLI tools
- SPIRE agent framework (legacy note: side-by-side experiments with hardware auth)

## Zero Trust / Entra direction (docs)

**Hard requirement:** primary Entra phishing-resistant auth is **TPM-backed certificate-based authentication (no USB dongle)** for UX parity with Windows Hello–class device-bound credentials.

| Doc | Description |
|-----|-------------|
| [docs/README.md](docs/README.md) | Doc index |
| [Linux Zero Trust with Entra](docs/runbooks/linux-zero-trust-entra.md) | Master architecture & funding narrative |
| [TPM CBA (no USB)](docs/runbooks/tpm-cba-no-usb.md) | Virtual smart card in platform TPM |
| [AWX GPO parity](docs/runbooks/ansible-awx-gpo-parity.md) | Continuous Ansible policy + compliance |
| [Intune compliance bridge](docs/runbooks/intune-compliance-bridge.md) | status.json → custom compliance → CA |

Related automation repo: [ansible-workstation-environment](https://github.com/themark-net/ansible-workstation-environment).

## Usage

1. Clone this repo
2. Adjust `inventory.yml`
3. `ansible-playbook -i inventory.yml setup-workstation.yml --become`

See **docs/** for enterprise Zero Trust runbooks (Entra CBA, Intune, AWX).

## Notes

- Local user auth (e.g. SSSD OIDC) is deployed via Ansible and remains separate from cloud CBA.
- YubiKey/USB may exist for break-glass only; **not** required for day-to-day Entra auth under the no-USB requirement.
