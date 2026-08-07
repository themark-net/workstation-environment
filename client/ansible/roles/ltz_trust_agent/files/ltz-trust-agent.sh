#!/usr/bin/env bash
# ltz-trust-agent — MVP compliance/trust agent (production-shaped)
# Attests posture, stores ticket + optional device cert for 802.1X EAP-TLS.
set -euo pipefail

CONFIG="${LTZ_CONFIG:-/etc/ltz-trust/config.env}"
# shellcheck disable=SC1090
[[ -f "$CONFIG" ]] && source "$CONFIG"

STATE_DIR="${LTZ_STATE_DIR:-/var/lib/ltz-trust}"
STATUS_JSON="${LTZ_STATUS_JSON:-$STATE_DIR/status.json}"
TICKET_FILE="${LTZ_TICKET_FILE:-$STATE_DIR/ticket.json}"
DEVICE_CERT="${LTZ_DEVICE_CERT:-$STATE_DIR/device.crt}"
DEVICE_KEY="${LTZ_DEVICE_KEY:-$STATE_DIR/device.key}"
DEVICE_CA="${LTZ_DEVICE_CA:-$STATE_DIR/device-ca.crt}"
ATTESTor_URL="${LTZ_ATTESTOR_URL:-}"
COLLECTOR_URL="${LTZ_COLLECTOR_URL:-}"
DEVICE_ID_FILE="${LTZ_DEVICE_ID_FILE:-$STATE_DIR/device_id}"
STRICT_TPM="${LTZ_STRICT_TPM:-0}"

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

ticket_ok=false
ticket_exp=0
cert_exp=0
if [[ -f "$TICKET_FILE" ]]; then
  ticket_exp=$(jq -r '.expires_at // 0' "$TICKET_FILE" 2>/dev/null || echo 0)
  if [[ "$ticket_exp" =~ ^[0-9]+$ ]] && (( ts < ticket_exp )); then
    ticket_ok=true
  fi
fi
if [[ -f "$DEVICE_CERT" ]]; then
  # refresh if cert missing or near expiry handled by re-attest when ticket stale
  cert_exp=$(openssl x509 -in "$DEVICE_CERT" -noout -enddate 2>/dev/null | sed 's/notAfter=//' || true)
fi

if [[ "$ticket_ok" != true && -n "$ATTESTor_URL" ]]; then
  nonce=$(openssl rand -hex 16 2>/dev/null || echo "$ts")
  evidence=$(jq -nc --argjson tpm "$tpm_present" --arg host "$hostname_f" --argjson ts "$ts" --arg nonce "$nonce" '{tpm_present:$tpm,hostname:$host,ts:$ts,nonce:$nonce}')
  if [[ "$STRICT_TPM" == "1" && "$tpm_present" != true ]]; then
    echo "STRICT_TPM=1 and no TPM; refusing attest" >&2
  else
    resp=$(curl -fsS -X POST "$ATTESTor_URL/v1/attest" -H 'Content-Type: application/json' -d "$(jq -nc --arg id "$device_id" --argjson ev "$evidence" '{device_id:$id,evidence:$ev}')" || true)
    if [[ -n "$resp" ]] && echo "$resp" | jq -e '.ticket' >/dev/null 2>&1; then
      echo "$resp" >"$TICKET_FILE"
      ticket_ok=true
      ticket_exp=$(echo "$resp" | jq -r '.expires_at')
      # Persist device cert for 802.1X when attestor returns it
      if echo "$resp" | jq -e '.device_cert.certificate_pem' >/dev/null 2>&1; then
        echo "$resp" | jq -r '.device_cert.certificate_pem' >"$DEVICE_CERT"
        echo "$resp" | jq -r '.device_cert.private_key_pem' >"$DEVICE_KEY"
        echo "$resp" | jq -r '.device_cert.ca_pem' >"$DEVICE_CA"
        chmod 0644 "$DEVICE_CERT" "$DEVICE_CA"
        chmod 0600 "$DEVICE_KEY"
        # Signal NetworkManager / wpa_supplicant if present
        if systemctl is-active --quiet NetworkManager 2>/dev/null; then
          nmcli connection reload 2>/dev/null || true
        fi
        if [[ -x /usr/local/lib/ltz/ltz-8021x-reload.sh ]]; then
          /usr/local/lib/ltz/ltz-8021x-reload.sh || true
        fi
      fi
    fi
  fi
fi

attested=$ticket_ok
device_cert_present=false
[[ -f "$DEVICE_CERT" && -f "$DEVICE_KEY" ]] && device_cert_present=true

jq -nc \
  --argjson schema 1 \
  --argjson ts "$ts" \
  --arg hostname "$hostname_f" \
  --arg device_id "$device_id" \
  --argjson tpm_present "$tpm_present" \
  --argjson attested "$attested" \
  --argjson ticket_expires_at "${ticket_exp:-0}" \
  --argjson device_cert_present "$device_cert_present" \
  --argjson lab false \
  '{schema:$schema,ts:$ts,hostname:$hostname,device_id:$device_id,tpm_present:$tpm_present,attested:$attested,ticket_expires_at:$ticket_expires_at,device_cert_present:$device_cert_present,lab:$lab}' \
  >"${STATUS_JSON}.tmp"
mv "${STATUS_JSON}.tmp" "$STATUS_JSON"
chmod 0644 "$STATUS_JSON"

if [[ -n "$COLLECTOR_URL" && "$attested" == true ]]; then
  curl -fsS -X POST "$COLLECTOR_URL/v1/report" -H 'Content-Type: application/json' -H "X-LTZ-Ticket: $(jq -r '.ticket' "$TICKET_FILE")" --data-binary @"$STATUS_JSON" || true
fi

echo "ltz-trust-agent: attested=$attested device_cert=$device_cert_present status=$STATUS_JSON"
