#!/usr/bin/env bash
# Semi-interactive lab helper: create soft-backed lab client cert for POC
# when full tpm2-pkcs11 init is environment-specific.
# For true TPM path, follow docs/poc/POC_PATH.md Phase A with tpm2_ptool.
set -euo pipefail
DIR=/var/lib/org-trust
mkdir -p "$DIR"
if [[ ! -f "$DIR/lab_client.key" ]]; then
  openssl req -newkey rsa:2048 -nodes -keyout "$DIR/lab_client.key" \
    -out "$DIR/lab_client.csr" -subj "/CN=$(hostname)/O=LTZ Lab User Sim"
  echo "CSR written to $DIR/lab_client.csr — sign with lab CA provisioner, install as lab_client.crt"
  echo "Then re-run trust-agent."
else
  echo "Key exists; place signed cert at $DIR/lab_client.crt"
fi
chmod 600 "$DIR/lab_client.key" 2>/dev/null || true
