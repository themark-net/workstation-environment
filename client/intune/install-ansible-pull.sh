#!/usr/bin/env bash
# Intune Linux **platform** script (run as Root) — seed ansible-pull timer.
# NOT a custom compliance discovery script. Do not upload this as discovery.
#
# Intune: Devices → Scripts and remediations → Platform scripts → Add → Linux
#   Execution context: Root
#   Frequency: Once (or weekly if you want re-seed)
#
# After first run, systemd ltz-ansible-pull.timer owns schedule.
set -euo pipefail

REPO_URL="${LTZ_PULL_REPO_URL:-https://github.com/themark-net/workstation-environment.git}"
BRANCH="${LTZ_PULL_BRANCH:-main}"
WORKDIR="${LTZ_PULL_WORKDIR:-/var/lib/ltz-pull}"
PLAYBOOK="${LTZ_PULL_PLAYBOOK:-client/ansible/playbooks/pull-local.yml}"

export DEBIAN_FRONTEND=noninteractive
if command -v apt-get >/dev/null 2>&1; then
  apt-get update -qq
  apt-get install -y -qq ansible-core git jq || apt-get install -y -qq ansible git jq
elif command -v dnf >/dev/null 2>&1; then
  dnf install -y ansible-core git jq || dnf install -y ansible git jq
fi

mkdir -p /usr/local/lib/ltz /etc/ltz-trust /var/lib/ltz-trust /var/log/ltz "$WORKDIR"

cat >/etc/ltz-trust/ansible-pull.env <<ENV
LTZ_PULL_REPO_URL="${REPO_URL}"
LTZ_PULL_BRANCH="${BRANCH}"
LTZ_PULL_WORKDIR="${WORKDIR}"
LTZ_PULL_PLAYBOOK="${PLAYBOOK}"
LTZ_PULL_ONLY_IF_CHANGED="1"
LTZ_PULL_SSH_KEY=""
ENV
chmod 0600 /etc/ltz-trust/ansible-pull.env

cat >/usr/local/lib/ltz/ltz-ansible-pull.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail
ENV_FILE="${LTZ_PULL_ENV:-/etc/ltz-trust/ansible-pull.env}"
# shellcheck disable=SC1090
[[ -f "$ENV_FILE" ]] && source "$ENV_FILE"
REPO_URL="${LTZ_PULL_REPO_URL:?}"
BRANCH="${LTZ_PULL_BRANCH:-main}"
WORKDIR="${LTZ_PULL_WORKDIR:-/var/lib/ltz-pull}"
PLAYBOOK="${LTZ_PULL_PLAYBOOK:-client/ansible/playbooks/pull-local.yml}"
mkdir -p "$WORKDIR" /var/log/ltz
OPTS=(-U "$REPO_URL" -C "$BRANCH" -d "$WORKDIR" --accept-host-key --only-if-changed)
ansible-pull "${OPTS[@]}" "$PLAYBOOK" >>/var/log/ltz/ansible-pull.log 2>&1
SH
chmod 0755 /usr/local/lib/ltz/ltz-ansible-pull.sh

cat >/etc/systemd/system/ltz-ansible-pull.service <<'UNIT'
[Unit]
Description=LTZ ansible-pull baseline
After=network-online.target
Wants=network-online.target
[Service]
Type=oneshot
EnvironmentFile=/etc/ltz-trust/ansible-pull.env
ExecStart=/usr/local/lib/ltz/ltz-ansible-pull.sh
UNIT

cat >/etc/systemd/system/ltz-ansible-pull.timer <<'UNIT'
[Unit]
Description=LTZ ansible-pull schedule
[Timer]
OnBootSec=5min
OnUnitActiveSec=1h
Persistent=true
RandomizedDelaySec=5min
[Install]
WantedBy=timers.target
UNIT

systemctl daemon-reload
systemctl enable --now ltz-ansible-pull.timer

echo '{"role":"ltz_ansible_pull","seeded_by":"intune_platform_script","ok":true}' \
  >/var/lib/ltz-trust/ansible-pull-status.json
echo "ltz ansible-pull timer enabled"
