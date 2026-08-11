#!/usr/bin/env bash
# Emit disk-encryption status JSON for compliance / ops.
set -euo pipefail
OUT="${LTZ_DISK_ENC_STATUS:-/var/lib/ltz-trust/disk-encryption.json}"
mkdir -p "$(dirname "$OUT")"

tpm_present=false
if [[ -e /dev/tpmrm0 || -e /dev/tpm0 ]]; then
  tpm_present=true
fi

root_src=$(findmnt -n -o SOURCE / 2>/dev/null || true)
root_fstype=$(findmnt -n -o FSTYPE / 2>/dev/null || true)
root_is_luks=false
root_crypt_name=""
tpm_enrolled=false

# Resolve LUKS under / or via cryptsetup status
if [[ -n "$root_src" ]]; then
  if cryptsetup isLuks "$root_src" 2>/dev/null; then
    root_is_luks=true
  elif [[ "$root_src" == /dev/mapper/* ]]; then
    root_crypt_name="${root_src#/dev/mapper/}"
    if cryptsetup status "$root_crypt_name" &>/dev/null; then
      root_is_luks=true
      # systemd-cryptenroll --tpm2-device=list when available
      if command -v systemd-cryptenroll >/dev/null 2>&1; then
        # Find underlying device
        underlying=$(cryptsetup status "$root_crypt_name" 2>/dev/null | awk '/device:/{print $2}')
        if [[ -n "${underlying:-}" ]] && systemd-cryptenroll "$underlying" 2>/dev/null | grep -qi tpm; then
          tpm_enrolled=true
        fi
      fi
    fi
  fi
fi

data_vol=false
recovery_escrowed=false
if compgen -G "/var/lib/ltz-trust/escrow/*.escrowed" > /dev/null; then
  recovery_escrowed=true
fi
if findmnt -n /var/lib/ltz-secure &>/dev/null || [[ -e /dev/mapper/ltz-secure ]]; then
  data_vol=true
fi

# encrypted if root LUKS or dedicated data volume present
disk_encrypted=false
if [[ "$root_is_luks" == true || "$data_vol" == true ]]; then
  disk_encrypted=true
fi

jq -nc \
  --argjson schema 1 \
  --argjson ts "$(date +%s)" \
  --argjson tpm_present "$tpm_present" \
  --argjson disk_encrypted "$disk_encrypted" \
  --argjson root_is_luks "$root_is_luks" \
  --argjson tpm_enrolled "$tpm_enrolled" \
  --argjson data_volume "$data_vol" \
  --argjson recovery_escrowed "$recovery_escrowed" \
  --arg root_source "${root_src:-}" \
  --arg root_fstype "${root_fstype:-}" \
  '{schema:$schema,ts:$ts,tpm_present:$tpm_present,disk_encrypted:$disk_encrypted,root_is_luks:$root_is_luks,tpm_enrolled:$tpm_enrolled,data_volume:$data_volume,root_source:$root_source,root_fstype:$root_fstype}' \
  >"${OUT}.tmp"
mv "${OUT}.tmp" "$OUT"
chmod 0644 "$OUT"
echo "ltz-tpm-luks-status: disk_encrypted=$disk_encrypted tpm_enrolled=$tpm_enrolled -> $OUT"
