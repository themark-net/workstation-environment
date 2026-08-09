#!/usr/bin/env bash
# Obtain device client cert: requires valid attestor ticket, then CSR → mint.
set -euo pipefail
# shellcheck disable=SC1091
[[ -f /etc/ltz-trust/device-cert.env ]] && source /etc/ltz-trust/device-cert.env
[[ -f /etc/ltz-trust/config.env ]] && source /etc/ltz-trust/config.env

STATE_DIR="${LTZ_STATE_DIR:-/var/lib/ltz-trust}"
CERT_DIR="${LTZ_DEVICE_CERT_DIR:-$STATE_DIR/pki}"
TICKET_FILE="${LTZ_TICKET_FILE:-$STATE_DIR/ticket.json}"
MINT_URL="${LTZ_CERT_MINT_URL:-}"
ATTESTOR_URL="${LTZ_ATTESTOR_URL:-}"

mkdir -p "$CERT_DIR"
chmod 0750 "$CERT_DIR"

if [[ ! -f "$TICKET_FILE" ]]; then
  echo "no ticket; run ltz-trust-agent first" >&2
  exit 1
fi
ticket=$(jq -r '.ticket // empty' "$TICKET_FILE")
exp=$(jq -r '.expires_at // 0' "$TICKET_FILE")
now=$(date +%s)
if [[ -z "$ticket" ]] || (( now >= exp )); then
  echo "ticket missing/expired; run ltz-trust-agent" >&2
  exit 1
fi

# Refresh agent if needed
if [[ -x /usr/local/lib/ltz/ltz-trust-agent.sh ]]; then
  /usr/local/lib/ltz/ltz-trust-agent.sh || true
  ticket=$(jq -r '.ticket' "$TICKET_FILE")
fi

device_id=$(tr -d ' \n' <"${STATE_DIR}/device_id")
key="$CERT_DIR/device.key"
csr="$CERT_DIR/device.csr"
crt="$CERT_DIR/device.crt"
chain="$CERT_DIR/chain.pem"

openssl req -new -newkey rsa:2048 -nodes \
  -keyout "$key" -out "$csr" \
  -subj "/CN=${device_id}/O=LTZ Lab Device"
chmod 0600 "$key"

if [[ -z "$MINT_URL" ]]; then
  echo "LTZ_CERT_MINT_URL unset" >&2
  exit 1
fi

resp=$(curl -fsS -X POST "${MINT_URL%/}/v1/sign" \
  -H "X-LTZ-Ticket: ${ticket}" \
  -H "Content-Type: application/pkcs10" \
  --data-binary @"$csr")

echo "$resp" | jq -r '.certificate' >"$crt"
echo "$resp" | jq -r '.chain_pem' >"$chain"
# ca.pem for verifying RADIUS server: use trust bundle if provided, else chain
if [[ -n "${LTZ_RADIUS_CA_FILE:-}" && -f "${LTZ_RADIUS_CA_FILE}" ]]; then
  cp "${LTZ_RADIUS_CA_FILE}" "$CERT_DIR/ca.pem"
elif [[ -f /etc/ltz-trust/lab-ca-bundle.pem ]]; then
  cp /etc/ltz-trust/lab-ca-bundle.pem "$CERT_DIR/ca.pem"
else
  # chain_pem is leaf+root; for lab intermediate-aware verify, prefer full chain file
  cp "$chain" "$CERT_DIR/ca.pem"
fi
chmod 0644 "$crt" "$chain" "$CERT_DIR/ca.pem"
chmod 0600 "$key"
chmod 0755 "$CERT_DIR" "$STATE_DIR" || true

# Build eapol_test config
RADIUS_IP="${LTZ_RADIUS_HOST:-}"
if [[ -z "$RADIUS_IP" && -n "${ATTESTOR_URL:-}" ]]; then
  # default: same host as attestor (lab_rp)
  RADIUS_IP=$(echo "$ATTESTOR_URL" | sed -E 's#https?://([^:/]+).*#\1#')
fi
RADIUS_IP="${RADIUS_IP:-10.42.0.146}"
RADIUS_SECRET="${LTZ_RADIUS_SECRET:-labradius}"

cat >"$CERT_DIR/eapol_test.conf" <<EOF
network={
  key_mgmt=WPA-EAP
  eap=TLS
  identity="${device_id}"
  ca_cert="${CERT_DIR}/ca.pem"
  client_cert="${crt}"
  private_key="${key}"
  eapol_flags=0
}
EOF
chmod 0644 "$CERT_DIR/eapol_test.conf"

echo "wrote $crt (device_id=$device_id)"
echo "eapol_test -c $CERT_DIR/eapol_test.conf -a $RADIUS_IP -s $RADIUS_SECRET -r 1"
