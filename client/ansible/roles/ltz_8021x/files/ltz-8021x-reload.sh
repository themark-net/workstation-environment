#!/usr/bin/env bash
# Reload 802.1X profile after device cert renew (called by trust agent).
set -euo pipefail
if systemctl is-active --quiet wpa_supplicant 2>/dev/null; then
  systemctl reload wpa_supplicant 2>/dev/null || systemctl restart wpa_supplicant 2>/dev/null || true
fi
if command -v nmcli >/dev/null 2>&1; then
  nmcli connection reload 2>/dev/null || true
  # Re-activate LTZ wired profile if present
  nmcli -t -f NAME connection show | grep -qx 'ltz-8021x' && nmcli connection up ltz-8021x 2>/dev/null || true
fi
exit 0
