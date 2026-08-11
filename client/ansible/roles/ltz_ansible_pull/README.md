# ltz_ansible_pull

Installs **ansible-pull** machinery on the host (systemd timer).
**Not** used by Intune compliance discovery scripts (those stay read-only).

## Paths

| Item | Default |
|------|---------|
| Work dir | `/var/lib/ltz-pull` |
| Timer | `ltz-ansible-pull.timer` |
| Playbook | `client/ansible/playbooks/pull-local.yml` (inside cloned repo) |

## Enable

```yaml
ltz_enable_ansible_pull: true
ltz_ansible_pull:
  repo_url: "https://github.com/themark-net/workstation-environment.git"
  repo_branch: "main"
  playbook: "client/ansible/playbooks/pull-local.yml"
  interval: "1h"
  only_if_changed: true
```

Bootstrap (push) can install the timer; Intune **root platform script** can also seed it — see `client/intune/`.
