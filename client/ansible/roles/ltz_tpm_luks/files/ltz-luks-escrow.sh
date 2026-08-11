#!/usr/bin/env bash
# Ensure a LUKS recovery-key slot exists and emit an escrow package (JSON).
# BitLocker analogue: recovery password + AD/Intune backup.
#
# Usage:
#   ltz-luks-escrow.sh --device DEV [--passphrase-file F] [--out PATH]
#   ltz-luks-escrow.sh --device DEV --mark-escrowed PATH
set -euo pipefail

DEVICE=""
PASS_FILE=""
OUT=""
MARK=""
HOSTNAME_F=$(hostname -f 2>/dev/null || hostname)
MACHINE_ID=$(cat /etc/machine-id 2>/dev/null || echo unknown)
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
EPOCH=$(date +%s)

while [[ $# -gt 0 ]]; do
  case "$1" in
    --device) DEVICE="${2:-}"; shift 2 ;;
    --passphrase-file) PASS_FILE="${2:-}"; shift 2 ;;
    --out) OUT="${2:-}"; shift 2 ;;
    --mark-escrowed) MARK="${2:-}"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [[ -n "$MARK" ]]; then
  mkdir -p "$(dirname "$MARK")"
  jq -nc --argjson ts "$EPOCH" --arg when "$TS" \
    '{escrowed:true,ts:$ts,when:$when}' >"$MARK"
  chmod 0600 "$MARK"
  exit 0
fi

[[ -n "$DEVICE" ]] || { echo "--device required" >&2; exit 2; }
[[ -n "$OUT" ]] || { echo "--out required" >&2; exit 2; }

if ! cryptsetup isLuks "$DEVICE" 2>/dev/null; then
  echo "not a LUKS device: $DEVICE" >&2
  exit 3
fi

mkdir -p "$(dirname "$OUT")"
umask 077

# Resolve: if recovery already escrowed and slot present, do not re-emit secrets
MARKER_DIR="/var/lib/ltz-trust/escrow"
MARKER="$MARKER_DIR/$(echo -n "$DEVICE" | sha256sum | awk '{print $1}').escrowed"
STATE_JSON="$MARKER_DIR/$(echo -n "$DEVICE" | sha256sum | awk '{print $1}').json"

has_recovery=false
if command -v systemd-cryptenroll >/dev/null 2>&1; then
  if systemd-cryptenroll "$DEVICE" 2>/dev/null | grep -Eiq 'recovery|password'; then
    # recovery keys show as "recovery key" in systemd-cryptenroll list
    if systemd-cryptenroll "$DEVICE" 2>/dev/null | grep -qi 'recovery'; then
      has_recovery=true
    fi
  fi
fi

# If already marked escrowed and recovery slot exists, write status-only package
if [[ -f "$MARKER" && "$has_recovery" == true ]]; then
  jq -nc \
    --arg schema "ltz-luks-escrow-v1" \
    --arg host "$HOSTNAME_F" \
    --arg machine_id "$MACHINE_ID" \
    --arg device "$DEVICE" \
    --arg when "$TS" \
    --argjson ts "$EPOCH" \
    --argjson already true \
    '{schema:$schema,host:$host,machine_id:$machine_id,device:$device,when:$when,ts:$ts,already_escrowed:$already,recovery_key:null,note:"recovery slot present; secret not re-exported"}' \
    >"$OUT"
  chmod 0600 "$OUT"
  echo "already escrowed: $DEVICE"
  exit 0
fi

# Need unlock credential for enroll
export PASSWORD=""
if [[ -n "$PASS_FILE" && -f "$PASS_FILE" ]]; then
  PASSWORD=$(cat "$PASS_FILE")
fi
if [[ -z "$PASSWORD" && -n "${LTZ_LUKS_PASSPHRASE:-}" ]]; then
  PASSWORD="$LTZ_LUKS_PASSPHRASE"
fi

if ! command -v systemd-cryptenroll >/dev/null 2>&1; then
  echo "systemd-cryptenroll required for recovery-key escrow" >&2
  exit 4
fi

if [[ -z "$PASSWORD" ]]; then
  echo "passphrase required to add recovery key (passphrase-file or LTZ_LUKS_PASSPHRASE)" >&2
  exit 2
fi

# Capture recovery key from systemd-cryptenroll (prints key to stdout)
# Format is multi-line; last meaningful line often the key. Use --recovery-key only.
RECOVERY_OUT=$(PASSWORD="$PASSWORD" systemd-cryptenroll --recovery-key "$DEVICE" 2>&1) || {
  # If recovery already exists, enroll may fail — treat as non-fatal for re-run
  if echo "$RECOVERY_OUT" | grep -qi 'already'; then
    has_recovery=true
  else
    echo "systemd-cryptenroll --recovery-key failed: $RECOVERY_OUT" >&2
    exit 5
  fi
}

RECOVERY_KEY=""
if [[ -n "${RECOVERY_OUT:-}" ]]; then
  # Prefer line that looks like recovery key (groups of digits/dashes)
  RECOVERY_KEY=$(echo "$RECOVERY_OUT" | grep -Eo '([0-9]{5}-){7}[0-9]{5}|[A-Za-z0-9+/_-]{20,}' | head -1 || true)
  if [[ -z "$RECOVERY_KEY" ]]; then
    # fallback: entire stdout stripped of obvious prompts
    RECOVERY_KEY=$(echo "$RECOVERY_OUT" | sed '/^$/d' | tail -1)
  fi
fi

if [[ -z "$RECOVERY_KEY" && "$has_recovery" != true ]]; then
  echo "could not capture recovery key output" >&2
  exit 6
fi

# UUID of LUKS if available
LUKS_UUID=$(cryptsetup luksUUID "$DEVICE" 2>/dev/null || echo "")

jq -nc \
  --arg schema "ltz-luks-escrow-v1" \
  --arg host "$HOSTNAME_F" \
  --arg machine_id "$MACHINE_ID" \
  --arg device "$DEVICE" \
  --arg luks_uuid "$LUKS_UUID" \
  --arg when "$TS" \
  --argjson ts "$EPOCH" \
  --arg recovery_key "${RECOVERY_KEY}" \
  --arg note "BitLocker-analogue recovery key. Store offline/controller only. Delete local after fetch." \
  '{
    schema:$schema,
    host:$host,
    machine_id:$machine_id,
    device:$device,
    luks_uuid:$luks_uuid,
    when:$when,
    ts:$ts,
    already_escrowed:false,
    recovery_key:(if $recovery_key=="" then null else $recovery_key end),
    note:$note
  }' >"$OUT"
chmod 0600 "$OUT"
# keep a host-local copy only until controller fetch marks escrowed
cp -a "$OUT" "$STATE_JSON"
chmod 0600 "$STATE_JSON"
echo "escrow package written: $OUT"
