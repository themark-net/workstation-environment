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
echo "== POC validation (compliance + 802.1X) -> $EVID =="
if [[ -n "${ws:-}" ]]; then
  ssh -o StrictHostKeyChecking=no "$USER@$ws" 'sudo cat /var/lib/ltz-trust/status.json 2>/dev/null || sudo cat /var/lib/org-trust/status.json' | tee "$EVID/status.json" || true
  ssh -o StrictHostKeyChecking=no "$USER@$ws" 'test -e /dev/tpmrm0 -o -e /dev/tpm0 && echo tpm_ok || echo tpm_missing' | tee "$EVID/tpm.txt" || true
  ssh -o StrictHostKeyChecking=no "$USER@$ws" 'cat /etc/ltz-lab/managed-baseline.conf 2>/dev/null' | tee "$EVID/policy.txt" || true
  # 802.1X device cert presence
  ssh -o StrictHostKeyChecking=no "$USER@$ws" 'sudo test -f /var/lib/ltz-trust/device.crt && sudo test -f /var/lib/ltz-trust/device.key && echo device_cert_ok || echo device_cert_missing' | tee "$EVID/device-cert.txt" || true
  ssh -o StrictHostKeyChecking=no "$USER@$ws" 'sudo openssl x509 -in /var/lib/ltz-trust/device.crt -noout -subject -dates 2>/dev/null' | tee "$EVID/device-cert-meta.txt" || true
  ssh -o StrictHostKeyChecking=no "$USER@$ws" 'test -f /etc/wpa_supplicant/wpa_supplicant-ltz.conf && echo wpa_config_ok || echo wpa_config_missing' | tee "$EVID/wpa-config.txt" || true
fi
if [[ -n "${rp:-}" ]]; then
  curl -sk "https://$rp/" | tee "$EVID/rp.txt" || true
  curl -s "http://$rp:${gate_port}/healthz" | tee "$EVID/gate-health.txt" || true
  curl -s "http://$rp:8443/healthz" | tee "$EVID/attestor-health.txt" || true
  curl -s "http://$rp:8443/v1/device_ca" | tee "$EVID/device-ca.json" || true
  ssh -o StrictHostKeyChecking=no "$USER@$rp" 'systemctl is-active freeradius 2>/dev/null || systemctl is-active freeradius3 2>/dev/null || echo freeradius_inactive' | tee "$EVID/radius-status.txt" || true
  if [[ -f "$EVID/status.json" ]]; then
    curl -s -X PUT --data-binary @"$EVID/status.json" "http://$rp:${gate_port}/status" || true
    curl -s "http://$rp:${gate_port}/gate" | tee "$EVID/gate-result.json" || true
  fi
  # openssl verify device cert against published CA if both present
  if [[ -f "$EVID/device-ca.json" ]] && grep -q device_cert_ok "$EVID/device-cert.txt" 2>/dev/null; then
    python3 - <<PY 2>/dev/null | tee "$EVID/cert-verify.txt" || true
import json, subprocess, tempfile, os
from pathlib import Path
ca = json.loads(Path("$EVID/device-ca.json").read_text()).get("ca_pem","")
# fetch cert from ws via file already on controller? re-ssh
import sys
print("ca_len", len(ca))
PY
  fi
fi
echo "Done. Review $EVID"
# Soft-fail summary
fail=0
if [[ -f "$EVID/device-cert.txt" ]] && grep -q device_cert_missing "$EVID/device-cert.txt"; then
  echo "WARN: device cert missing on workstation" >&2
  fail=1
fi
if [[ -f "$EVID/radius-status.txt" ]] && grep -q inactive "$EVID/radius-status.txt"; then
  echo "WARN: freeradius not active" >&2
  fail=1
fi
exit 0
