#!/usr/bin/env bash
# Optional public-key wrap of escrow JSON before it leaves the host.
# Supports: age (preferred) or openssl RSA public key (PEM).
set -euo pipefail
IN=""
OUT=""
METHOD="none"   # none | age | openssl
PUBKEY=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --in) IN="${2:-}"; shift 2 ;;
    --out) OUT="${2:-}"; shift 2 ;;
    --method) METHOD="${2:-}"; shift 2 ;;
    --pubkey) PUBKEY="${2:-}"; shift 2 ;;
    *) echo "unknown: $1" >&2; exit 2 ;;
  esac
done
[[ -f "$IN" ]] || { echo "missing --in" >&2; exit 2; }
[[ -n "$OUT" ]] || { echo "missing --out" >&2; exit 2; }

case "$METHOD" in
  none)
    cp -a "$IN" "$OUT"
    ;;
  age)
    command -v age >/dev/null || { echo "age not installed" >&2; exit 3; }
    [[ -f "$PUBKEY" ]] || { echo "age recipient file required" >&2; exit 2; }
    age -R "$PUBKEY" -o "$OUT" <"$IN"
    ;;
  openssl)
    command -v openssl >/dev/null || { echo "openssl missing" >&2; exit 3; }
    [[ -f "$PUBKEY" ]] || { echo "openssl pubkey required" >&2; exit 2; }
    # hybrid: random aes key + rsa wrap
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    openssl rand -out "$tmp/key.bin" 32
    openssl enc -aes-256-cbc -salt -pbkdf2 -in "$IN" -out "$tmp/payload.bin" -pass file:"$tmp/key.bin"
    openssl pkeyutl -encrypt -pubin -inkey "$PUBKEY" -in "$tmp/key.bin" -out "$tmp/key.enc"
    {
      echo "ltz-escrow-openssl-v1"
      base64 -w0 "$tmp/key.enc"; echo
      base64 -w0 "$tmp/payload.bin"; echo
    } >"$OUT"
    ;;
  *)
    echo "unknown method $METHOD" >&2
    exit 2
    ;;
esac
chmod 0600 "$OUT"
echo "wrapped -> $OUT method=$METHOD"
