#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TFDIR="$ROOT/terraform"
OUT="$ROOT/ansible/inventory/hosts.yml"
TF=$(command -v tofu || command -v terraform)
cd "$TFDIR"
ipv4_json=$($TF output -json ipv4 2>/dev/null || echo '{}')
user=$($TF output -raw lab_user 2>/dev/null || echo ltz)
domain=$($TF output -raw dns_domain 2>/dev/null || echo ltz.lab)
python3 - "$OUT" "$ipv4_json" "$user" "$domain" <<'PY'
import json, sys, pathlib
out, ipv4_s, user, domain = sys.argv[1:5]
ipv4 = json.loads(ipv4_s)

def ip(k):
    return ipv4.get(k) or ""

lines = [
    "all:",
    "  vars:",
    f"    ansible_user: {user}",
    "    ansible_python_interpreter: /usr/bin/python3",
    f"    lab_domain: {domain}",
    f"    lab_ca_dns: ltz-lab-ca.{domain}",
    "  children:",
    "    lab_ca:",
    "      hosts:",
    "        ltz-lab-ca:",
    f"          ansible_host: {ip('ca')}",
    "    lab_rp:",
    "      hosts:",
    "        ltz-lab-rp:",
    f"          ansible_host: {ip('rp')}",
    "    lab_workstations:",
    "      hosts:",
    "        ltz-lab-ws1:",
    f"          ansible_host: {ip('ws1')}",
    "    lab_workloads:",
    "      hosts:",
    "        ltz-lab-svc-a:",
    f"          ansible_host: {ip('svc_a')}",
    "          workload_name: svc-a",
    "        ltz-lab-svc-b:",
    f"          ansible_host: {ip('svc_b')}",
    "          workload_name: svc-b",
]
if ip("spire"):
    lines += [
        "    lab_spire:",
        "      hosts:",
        "        ltz-lab-spire:",
        f"          ansible_host: {ip('spire')}",
    ]
pathlib.Path(out).write_text("\n".join(lines) + "\n")
print(f"Wrote {out}")
for k, v in ipv4.items():
    print(f"  {k}: {v}")
PY
