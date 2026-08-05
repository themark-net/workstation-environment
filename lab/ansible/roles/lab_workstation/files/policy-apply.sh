#!/usr/bin/env bash
set -euo pipefail
MARKER=/etc/ltz-lab/managed-baseline.conf
mkdir -p /etc/ltz-lab
gen=1
if [[ -f /var/lib/org-trust/policy_gen ]]; then
  read -r gen _ < /var/lib/org-trust/policy_gen || gen=1
  gen=$((gen + 1))
fi
ts=$(date +%s)
cat >"$MARKER" <<EOF
# Managed by LTZ lab policy_gen=$gen — do not edit
ltz_lab_baseline=1
policy_gen=$gen
applied_ts=$ts
EOF
echo "$gen $ts" > /var/lib/org-trust/policy_gen
# re-run trust agent if present
if [[ -x /usr/local/lib/ltz/trust-agent.sh ]]; then
  /usr/local/lib/ltz/trust-agent.sh || true
fi
