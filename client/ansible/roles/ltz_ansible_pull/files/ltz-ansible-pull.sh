#!/usr/bin/env bash
# Run ansible-pull for LTZ baseline (idempotent local playbook).
set -euo pipefail
ENV_FILE="${LTZ_PULL_ENV:-/etc/ltz-trust/ansible-pull.env}"
# shellcheck disable=SC1090
[[ -f "$ENV_FILE" ]] && source "$ENV_FILE"

REPO_URL="${LTZ_PULL_REPO_URL:?repo url required}"
BRANCH="${LTZ_PULL_BRANCH:-main}"
WORKDIR="${LTZ_PULL_WORKDIR:-/var/lib/ltz-pull}"
PLAYBOOK="${LTZ_PULL_PLAYBOOK:-client/ansible/playbooks/pull-local.yml}"
ONLY_IF_CHANGED="${LTZ_PULL_ONLY_IF_CHANGED:-1}"

mkdir -p "$WORKDIR" /var/log/ltz
OPTS=(-U "$REPO_URL" -C "$BRANCH" -d "$WORKDIR" --accept-host-key)
[[ "$ONLY_IF_CHANGED" == "1" ]] && OPTS+=(--only-if-changed)
if [[ -n "${LTZ_PULL_SSH_KEY:-}" && -f "${LTZ_PULL_SSH_KEY}" ]]; then
  export GIT_SSH_COMMAND="ssh -i ${LTZ_PULL_SSH_KEY} -o StrictHostKeyChecking=accept-new"
fi

cd /
if command -v ansible-pull >/dev/null 2>&1; then
  ansible-pull "${OPTS[@]}" "$PLAYBOOK" >>/var/log/ltz/ansible-pull.log 2>&1 || {
    echo "ansible-pull failed rc=$?" >>/var/log/ltz/ansible-pull.log
    exit 1
  }
else
  echo "ansible-pull not installed" >&2
  exit 2
fi

jq -nc --argjson ts "$(date +%s)" --arg repo "$REPO_URL" --arg branch "$BRANCH" \
  '{role:"ltz_ansible_pull",ok:true,ts:$ts,repo:$repo,branch:$branch}' \
  >/var/lib/ltz-trust/ansible-pull-status.json || true
