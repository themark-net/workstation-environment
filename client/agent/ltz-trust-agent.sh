#!/usr/bin/env bash
# ltz-trust-agent — challenge/response client (backend-agnostic)
#
# Talks only to LTZ_ATTESTOR_URL. Does not know/care if attestor uses
# local HMAC verification or Microsoft Azure Attestation behind the scenes.
#
# Flow:
#   1) reuse unexpired ticket if present
#   2) POST /v1/challenge
#   3) build evidence (HMAC over server nonce; optional TPM quote metadata)
#   4) POST /v1/attest → store ticket
#   5) write status.json for Intune discovery
set -euo pipefail

CONFIG="${LTZ_CONFIG:-/etc/ltz-trust/config.env}"
# shellcheck disable=SC1090
[[ -f "$CONFIG" ]] && source "$CONFIG"

STATE_DIR="${LTZ_STATE_DIR:-/var/lib/ltz-trust}"
STATUS_JSON="${LTZ_STATUS_JSON:-$STATE_DIR/status.json}"
TICKET_FILE="${LTZ_TICKET_FILE:-$STATE_DIR/ticket.json}"
SECRET_FILE="${LTZ_DEVICE_SECRET_FILE:-$STATE_DIR/device_secret}"
ATTESTOR_URL="${LTZ_ATTESTOR_URL:-}"
COLLECTOR_URL="${LTZ_COLLECTOR_URL:-}"
DEVICE_ID_FILE="${LTZ_DEVICE_ID_FILE:-$STATE_DIR/device_id}"
STRICT_TPM="${LTZ_STRICT_TPM:-0}"
JOIN_TOKEN="${LTZ_JOIN_TOKEN:-lab-join}"

mkdir -p "$STATE_DIR"
chmod 0750 "$STATE_DIR"

ts=$(date +%s)
hostname_f=$(hostname -f 2>/dev/null || hostname)

tpm_present=false
if [[ -e /dev/tpmrm0 || -e /dev/tpm0 ]]; then
  tpm_present=true
fi

if [[ ! -f "$DEVICE_ID_FILE" ]]; then
  echo "ltz-$(cat /etc/machine-id 2>/dev/null || echo unknown)" >"$DEVICE_ID_FILE"
fi
device_id=$(tr -d ' \n' <"$DEVICE_ID_FILE")

# --- helpers ---
ensure_enrolled() {
  if [[ -f "$SECRET_FILE" && -s "$SECRET_FILE" ]]; then
    return 0
  fi
  [[ -n "$ATTESTOR_URL" ]] || return 1
  local body resp secret
  body=$(jq -nc --arg id "$device_id" --arg tok "$JOIN_TOKEN" --arg host "$hostname_f" \
    '{device_id:$id,join_token:$tok,meta:{hostname:$host,class:"agent"}}')
  resp=$(curl -fsS -X POST "$ATTESTOR_URL/v1/enroll" -H 'Content-Type: application/json' -d "$body" || true)
  secret=$(echo "$resp" | jq -r '.device_secret // empty')
  if [[ -z "$secret" ]]; then
    echo "enroll failed: $resp" >&2
    return 1
  fi
  umask 077
  printf '%s\n' "$secret" >"$SECRET_FILE"
  chmod 0600 "$SECRET_FILE"
  echo "enrolled device_id=$device_id (device_secret stored)"
}

evidence_hmac() {
  local secret="$1" challenge_id="$2" nonce="$3" tpm_flag="$4"
  local material
  material="ltz-evidence-v1|${device_id}|${challenge_id}|${nonce}|${ts}|${tpm_flag}|${hostname_f}"
  printf '%s' "$material" | openssl dgst -sha256 -hmac "$secret" | awk '{print $2}'
}

try_tpm_quote_meta() {
  # Best-effort: record that we could touch TPM; full AK quote verify is optional server-side.
  # Qualifying data = challenge nonce (hex) when tpm2_quote is available.
  local nonce="$1"
  if ! command -v tpm2_quote >/dev/null 2>&1; then
    return 1
  fi
  # Soft metadata only — production can replace with real AK quote files.
  jq -nc --arg n "$nonce" --arg tool "tpm2_quote" \
    '{scheme:"tpm2_quote_meta",qualifying_data:$n,tool:$tool,note:"nonce-bound metadata; upgrade to full AK quote as needed"}'
}

# --- main ---
ticket_ok=false
ticket_exp=0
if [[ -f "$TICKET_FILE" ]]; then
  ticket_exp=$(jq -r '.expires_at // 0' "$TICKET_FILE" 2>/dev/null || echo 0)
  if [[ "$ticket_exp" =~ ^[0-9]+$ ]] && (( ts < ticket_exp )); then
    ticket_ok=true
  fi
fi

if [[ "$ticket_ok" != true && -n "$ATTESTOR_URL" ]]; then
  if [[ "$STRICT_TPM" == "1" && "$tpm_present" != true ]]; then
    echo "STRICT_TPM=1 and no TPM; refusing attest" >&2
  elif ensure_enrolled; then
    secret=$(tr -d ' \n' <"$SECRET_FILE")
    ch=$(curl -fsS -X POST "$ATTESTOR_URL/v1/challenge" -H 'Content-Type: application/json' \
      -d "$(jq -nc --arg id "$device_id" '{device_id:$id}')" || true)
    challenge_id=$(echo "$ch" | jq -r '.challenge_id // empty')
    nonce=$(echo "$ch" | jq -r '.nonce // empty')
    if [[ -z "$challenge_id" || -z "$nonce" ]]; then
      echo "challenge failed: $ch" >&2
    else
      tpm_flag=0
      [[ "$tpm_present" == true ]] && tpm_flag=1
      proof=$(evidence_hmac "$secret" "$challenge_id" "$nonce" "$tpm_flag")
      quote_json="{}"
      if [[ "$tpm_present" == true ]]; then
        if qm=$(try_tpm_quote_meta "$nonce"); then
          quote_json="$qm"
        fi
      fi
      evidence=$(jq -nc \
        --arg scheme "hmac_v1" \
        --arg cid "$challenge_id" \
        --arg nonce "$nonce" \
        --argjson ts "$ts" \
        --argjson tpm "$tpm_present" \
        --arg host "$hostname_f" \
        --arg hmac "$proof" \
        --argjson quote "$quote_json" \
        '{
          scheme:$scheme,
          challenge_id:$cid,
          nonce:$nonce,
          ts:$ts,
          tpm_present:$tpm,
          hostname:$host,
          proof_hmac:$hmac
        } + (if ($quote|type)=="object" and ($quote|length)>0 then {tpm_quote:$quote} else {} end)')
      body=$(jq -nc --arg id "$device_id" --arg cid "$challenge_id" --argjson ev "$evidence" \
        '{device_id:$id,challenge_id:$cid,evidence:$ev}')
      resp=$(curl -fsS -X POST "$ATTESTOR_URL/v1/attest" -H 'Content-Type: application/json' -d "$body" || true)
      if [[ -n "$resp" ]] && echo "$resp" | jq -e '.ticket' >/dev/null 2>&1; then
        echo "$resp" >"$TICKET_FILE"
        chmod 0640 "$TICKET_FILE"
        ticket_ok=true
        ticket_exp=$(echo "$resp" | jq -r '.expires_at')
        echo "attest ok backend=$(echo "$resp" | jq -r '.backend // "?"')"
      else
        echo "attest failed: $resp" >&2
      fi
    fi
  fi
fi

attested=$ticket_ok


# Disk encryption status (from ltz_tpm_luks helper)
disk_encrypted=false
DISK_JSON="${LTZ_DISK_ENC_STATUS:-$STATE_DIR/disk-encryption.json}"
if [[ -f "$DISK_JSON" ]]; then
  disk_encrypted=$(jq -r '.disk_encrypted // false' "$DISK_JSON" 2>/dev/null || echo false)
fi
# normalize boolean for jq
[[ "$disk_encrypted" == "true" ]] || disk_encrypted=false

jq -nc \
  --argjson schema 2 \
  --argjson ts "$ts" \
  --arg hostname "$hostname_f" \
  --arg device_id "$device_id" \
  --argjson tpm_present "$tpm_present" \
  --argjson attested "$attested" \
  --argjson ticket_expires_at "${ticket_exp:-0}" \
  --argjson disk_encrypted "$disk_encrypted" \
  --argjson lab false \
  '{schema:$schema,ts:$ts,hostname:$hostname,device_id:$device_id,tpm_present:$tpm_present,attested:$attested,ticket_expires_at:$ticket_expires_at,disk_encrypted:$disk_encrypted,lab:$lab,ticket_fresh:$attested}' \
  >"${STATUS_JSON}.tmp"
mv "${STATUS_JSON}.tmp" "$STATUS_JSON"
chmod 0644 "$STATUS_JSON"

if [[ -n "$COLLECTOR_URL" && "$attested" == true && -f "$TICKET_FILE" ]]; then
  curl -fsS -X POST "$COLLECTOR_URL/v1/report" \
    -H 'Content-Type: application/json' \
    -H "X-LTZ-Ticket: $(jq -r '.ticket' "$TICKET_FILE")" \
    --data-binary @"$STATUS_JSON" || true
fi

echo "ltz-trust-agent: attested=$attested tpm=$tpm_present disk_encrypted=$disk_encrypted status=$STATUS_JSON"
