#!/bin/bash
# sb-diag.sh — Secure Boot signature mismatch forensics
set -euo pipefail

OUT=sb-diag-$(date +%Y%m%d-%H%M%S).txt
exec >$OUT 2>&1

echo "=== SECURE BOOT DIAGNOSTIC ==="
echo "Host: $(hostname)"
echo "Date: $(date)"
echo

echo "1. Secure Boot state"
mokutil --sb-state 2>/dev/null || echo "mokutil not available"
echo

echo "2. Enrolled MOK keys"
mokutil --list-enrolled 2>/dev/null || echo "mokutil not available"
echo

echo "3. Shim and grub package versions"
dpkg -l shim-signed grub-efi-amd64-signed 2>/dev/null || echo "packages not found"
echo "Held packages:"
apt-mark showhold 2>/dev/null || true
echo

echo "4. Apt history: shim, grub, kernel, nvidia"
if [ -f /var/log/apt/history.log ]; then
    awk '
        /^Start-Date:/ { date=$0; keep=0 }
        /Commandline:.* (shim-signed|grub-efi|linux-image|nvidia-)/ { keep=1 }
        keep { print date; print; print "" }
    ' /var/log/apt/history.log
    for f in /var/log/apt/history.log.[0-9].gz; do
        [ -f "$f" ] || continue
        zcat "$f" | awk '
            /^Start-Date:/ { date=$0; keep=0 }
            /Commandline:.* (shim-signed|grub-efi|linux-image|nvidia-)/ { keep=1 }
            keep { print date; print; print "" }
        '
    done
fi
echo

echo "5. Journal: shim/grub verification errors (previous boot)"
journalctl -b -1 --no-pager 2>/dev/null | grep -iE 'shim|Secure Boot|signature|dbx|verification' || echo "no matching journal entries"
echo

echo "6. dmesg from current boot: signature/db issues"
dmesg 2>/dev/null | grep -iE 'signature|Secure Boot|dbx|shim' || echo "no matching dmesg entries"
echo

echo "7. Running kernel and its signing"
echo "Kernel: $(uname -r)"
if [ -f "/boot/vmlinuz-$(uname -r)" ]; then
    sbverify --list "/boot/vmlinuz-$(uname -r)" 2>/dev/null || true
    openssl cms -inform DER -in "/boot/vmlinuz-$(uname -r)" -verify -noverify -purpose any 2>&1 || echo "could not parse kernel signature"
fi
echo

echo "8. EFI boot entries"
efibootmgr -v 2>/dev/null || echo "efibootmgr not available"
echo

echo "9. EFI partition layout"
findmnt /boot/efi 2>/dev/null || echo "/boot/efi not mounted"
ls -la /boot/efi/EFI/ 2>/dev/null || echo "EFI dir not readable"
echo

echo "10. DKMS modules and signing"
dkms status 2>/dev/null || echo "dkms not available"
if command -v mokutil &>/dev/null; then
    echo "MOK keys used by dkms (if any):"
    ls /var/lib/shim-signed/mok/ 2>/dev/null || echo "no /var/lib/shim-signed/mok directory"
fi
echo

echo "11. Cross-check: does enrolled MOK match local MOK key?"
if [ -f /var/lib/shim-signed/mok/MOK.der ]; then
    echo "Local MOK.der fingerprint:"
    openssl x509 -inform DER -in /var/lib/shim-signed/mok/MOK.der -noout -fingerprint -sha256 2>/dev/null
    echo "Compare against enrolled list above (section 2)."
else
    echo "No /var/lib/shim-signed/mok/MOK.der — key may live elsewhere or was deleted."
    find /var/lib /root /etc -name 'MOK.der' 2>/dev/null || echo "no MOK.der found anywhere"
fi
echo

echo "12. Nvidia driver package"
dpkg -l 'nvidia-*' 2>/dev/null || echo "no nvidia packages found"
echo

echo "=== END DIAGNOSTIC ==="
echo "Output saved to $OUT"