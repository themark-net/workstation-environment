#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INV="$ROOT/ansible/inventory/hosts.yml"
USER=$(grep -E 'ansible_user:' "$INV" | head -1 | awk '{print $2}')
mapfile -t hosts < <(grep ansible_host "$INV" | awk '{print $2}' | sort -u)
echo "Waiting for SSH as $USER on: ${hosts[*]}"
for h in "${hosts[@]}"; do
  [[ -z "$h" || "$h" == "None" ]] && continue
  echo -n "  $h ... "
  for i in $(seq 1 60); do
    if ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$USER@$h" true 2>/dev/null; then
      echo ok
      break
    fi
    sleep 5
    if [[ $i -eq 60 ]]; then echo TIMEOUT; exit 1; fi
  done
done
