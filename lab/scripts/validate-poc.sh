#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INV="$ROOT/ansible/inventory/hosts.yml"
EVID="$ROOT/evidence/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$EVID"
USER=$(grep -E 'ansible_user:' "$INV" | head -1 | awk '{print $2}')
ws=$(awk '/ltz-lab-ws1:/{f=1} f&&/ansible_host:/{print $2; exit}' "$INV")
rp=$(awk '/ltz-lab-rp:/{f=1} f&&/ansible_host:/{print $2; exit}' "$INV")
gate_port=8089
echo "== POC validation -> $EVID =="
if [[ -n "${ws:-}" ]]; then
  ssh -o StrictHostKeyChecking=no "$USER@$ws" 'sudo cat /var/lib/org-trust/status.json' | tee "$EVID/status.json" || true
  ssh -o StrictHostKeyChecking=no "$USER@$ws" 'test -e /dev/tpmrm0 -o -e /dev/tpm0 && echo tpm_ok || echo tpm_missing' | tee "$EVID/tpm.txt" || true
  ssh -o StrictHostKeyChecking=no "$USER@$ws" 'cat /etc/ltz-lab/managed-baseline.conf 2>/dev/null' | tee "$EVID/policy.txt" || true
fi
if [[ -n "${rp:-}" ]]; then
  curl -sk "https://$rp/" | tee "$EVID/rp.txt" || true
  curl -s "http://$rp:${gate_port}/healthz" | tee "$EVID/gate-health.txt" || true
  if [[ -f "$EVID/status.json" ]]; then
    curl -s -X PUT --data-binary @"$EVID/status.json" "http://$rp:${gate_port}/status" || true
    curl -s "http://$rp:${gate_port}/gate" | tee "$EVID/gate-result.json" || true
  fi
fi
echo "Done. Review $EVID"
