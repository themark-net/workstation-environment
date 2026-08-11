#!/usr/bin/env bash
# Intune Linux custom compliance discovery script (MVP)
set -euo pipefail
STATUS="${LTZ_STATUS_JSON:-/var/lib/ltz-trust/status.json}"
DISK="${LTZ_DISK_ENC_STATUS:-/var/lib/ltz-trust/disk-encryption.json}"
NOW=$(date +%s)

if [[ ! -f "$STATUS" ]]; then
  echo '{"attested":false,"tpm_present":false,"ticket_fresh":false,"disk_encrypted":false,"status_age_sec":999999}'
  exit 0
fi

attested=$(jq -r '.attested // false' "$STATUS")
tpm=$(jq -r '.tpm_present // false' "$STATUS")
ts=$(jq -r '.ts // 0' "$STATUS")
exp=$(jq -r '.ticket_expires_at // 0' "$STATUS")
age=$(( NOW - ts ))
ticket_fresh=false
if [[ "$attested" == "true" && "$exp" =~ ^[0-9]+$ ]] && (( NOW < exp )); then
  ticket_fresh=true
fi

disk_encrypted=false
if [[ -f "$DISK" ]]; then
  disk_encrypted=$(jq -r '.disk_encrypted // false' "$DISK")
fi

jq -nc \
  --argjson attested "$attested" \
  --argjson tpm_present "$tpm" \
  --argjson ticket_fresh "$ticket_fresh" \
  --argjson disk_encrypted "$disk_encrypted" \
  --argjson status_age_sec "$age" \
  '{attested:$attested,tpm_present:$tpm_present,ticket_fresh:$ticket_fresh,disk_encrypted:$disk_encrypted,status_age_sec:$status_age_sec}'
