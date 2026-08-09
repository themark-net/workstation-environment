# ltz_intune_prereqs

Production-shaped host baseline so a user can **open the Intune app and enroll** without manual package installs.

Installs:

- `microsoft-edge-stable`
- `intune-portal` (Microsoft Intune app)
- `microsoft-identity-broker`
- `jq` / curl / ca-certificates
- Optionally `ubuntu-desktop-minimal` (GNOME; required by Microsoft for Linux enrollment)

## Usage

```yaml
- hosts: workstations
  become: true
  roles:
    - role: ltz_intune_prereqs
      vars:
        ltz_intune_install_desktop: true
```

Lab workstations pull this role via `lab/ansible` `roles_path` (see `lab/ansible/playbooks/intune-prereqs.yml`).
