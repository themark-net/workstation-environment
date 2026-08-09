#!/usr/bin/env bash
# Show workstation vs server attestation status from the lab inventory.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INV="$ROOT/ansible/inventory/hosts.yml"
USER=$(awk '/ansible_user:/{print $2; exit}' "$INV")

pick_host() {
  local group="$1"
  # naive yaml: first ansible_host under group block
  awk -v g="$group:" '
    $0 ~ g {in_g=1; next}
    in_g && /ansible_host:/ {print $2; exit}
    in_g && /^[[:space:]]*[a-z_]+:/ && $0 !~ /hosts:/ && $0 !~ /ansible_/ && $0 !~ /ltz_/ && $0 !~ /workload/ {if ($1 !~ /ltz-/) in_g=0}
  ' "$INV"
}

ws_ip=$(pick_host "lab_workstations")
# servers: first under lab_servers hosts
srv_ip=$(awk '
  /lab_servers:/ {s=1}
  s && /ltz-lab-svc-a:/ {a=1}
  a && /ansible_host:/ {print $2; exit}
' "$INV")
rp_ip=$(awk '/lab_rp:/ {r=1} r && /ansible_host:/ {print $2; exit}' "$INV")

echo "=== LTZ dual-path attestation demo ==="
echo "attestor/collector (rp): $rp_ip"
echo "workstation (GUI/Intune path): $ws_ip"
echo "server (headless attestor path): $srv_ip"
echo

if [[ -n "${rp_ip:-}" ]]; then
  echo "--- attestor health ---"
  curl -fsS "http://${rp_ip}:8443/healthz" || echo "attestor DOWN"
  echo
  echo "--- collector health ---"
  curl -fsS "http://${rp_ip}:8089/healthz" 2>/dev/null || curl -fsS "http://${rp_ip}:8089/" 2>/dev/null || echo "collector check skipped/failed"
  echo
fi

for label_ip in "workstation:${ws_ip}" "server:${srv_ip}"; do
  label=${label_ip%%:*}
  ip=${label_ip##*:}
  [[ -z "$ip" ]] && continue
  echo "--- $label ($ip) ---"
  ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new \
    "${USER}@${ip}" '
      echo "class: $(cat /etc/ltz-host-class 2>/dev/null || echo unknown)"
      echo "role:  $(cat /etc/ltz-lab-role 2>/dev/null || echo unknown)"
      echo "tpm:   $(ls /dev/tpmrm0 /dev/tpm0 2>/dev/null | tr "\n" " " || echo none)"
      echo "gdm:   $(systemctl is-active gdm3 2>/dev/null || echo inactive)"
      echo "intune:$(dpkg -l intune-portal 2>/dev/null | awk "/^ii/{print \$3}" || echo not-installed)"
      echo "status.json:"
      sudo cat /var/lib/ltz-trust/status.json 2>/dev/null | jq . || echo "  MISSING — run make ansible-mvp"
    ' || echo "  SSH failed"
  echo
done

echo "Done. Workstation: open intune-portal at Proxmox console for Intune enroll."
echo "Server: attestation is headless — no Intune required."
