#!/usr/bin/env bash
set -euo pipefail
OUT=/var/lib/org-trust/status.json
POLICY_GEN_FILE=/var/lib/org-trust/policy_gen
mkdir -p /var/lib/org-trust
ts=$(date +%s)
tpm_present=false
tpm_cba_key=false
tpm_cba_cert=false
if [[ -e /dev/tpmrm0 || -e /dev/tpm0 ]]; then tpm_present=true; fi
# Best-effort PKCS#11 object detection (lab)
if command -v tpm2_ptool >/dev/null 2>&1; then
  if tpm2_ptool listtokens 2>/dev/null | grep -qi entra || tpm2_ptool listtokens 2>/dev/null | grep -qi ltz; then
    tpm_cba_key=true
  fi
fi
if [[ -f /var/lib/org-trust/lab_client.crt ]]; then
  tpm_cba_cert=true
fi
policy_gen=0
policy_gen_ts=0
if [[ -f "$POLICY_GEN_FILE" ]]; then
  # format: gen ts
  read -r policy_gen policy_gen_ts <"$POLICY_GEN_FILE" || true
fi
cat >"${OUT}.tmp" <<EOF
{
  "schema": 1,
  "ts": $ts,
  "hostname": "$(hostname -f 2>/dev/null || hostname)",
  "policy_gen": ${policy_gen:-0},
  "policy_gen_ts": ${policy_gen_ts:-0},
  "tpm_present": $tpm_present,
  "tpm_cba_key": $tpm_cba_key,
  "tpm_cba_cert": $tpm_cba_cert,
  "luks": false,
  "secure_boot": false,
  "lab": true
}
EOF
mv "${OUT}.tmp" "$OUT"
chmod 0644 "$OUT"
