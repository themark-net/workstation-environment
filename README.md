# Workstation Environment

Ansible-based setup for uniform Linux workstation/desktop environment.

## Supported
- RHEL-based: Rocky, Alma, RHEL
- Debian-based: Ubuntu, Debian, Mint, Pop!_OS, Zorin
- Basic support for non-systemd

## Features
- Core tools: screen, vim, dev suite
- Unlimited bash history
- Podman + K8s tools
- Ceph client
- Modern sysadmin CLI tools
- SPIRE agent framework (side-by-side with YubiKey PAM/login)

## Usage
1. Clone this repo
2. ansible-playbook -i inventory playbook.yml --become

See docs/ for details.

YubiKey login: configured side-by-side with traditional auth.
SPIRE: agent installed; server setup separate.

Tom Doerr inspired tools included where relevant.