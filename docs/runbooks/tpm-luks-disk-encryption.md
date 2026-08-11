# Runbook: TPM + LUKS disk encryption baseline

**Role:** `client/ansible/roles/ltz_tpm_luks`  
**Wired into:** `bootstrap-host.yml` when `ltz_enable_tpm_luks: true`  
**Compliance claim:** `disk_encrypted` via `/var/lib/ltz-trust/disk-encryption.json` → Intune discovery

---

## 1. Modes

| Mode | Use when | Effect |
|------|----------|--------|
| `assert` | Greenfield hosts installed with FDE | Verify LUKS root (or `ltz-secure` data vol); write status |
| `enroll` | Root already LUKS; bind TPM2 | `systemd-cryptenroll --tpm2-device=auto` (needs passphrase once) |
| `data_volume` | Lab / retrofit without re-install | Encrypted image/mapper at `/var/lib/ltz-secure` |

**This role does not re-encrypt an existing cleartext root.** Full-disk LUKS must be chosen at OS install (autoinstall/kickstart/image).

---

## 2. Vars

```yaml
ltz_enable_tpm_luks: true
ltz_tpm_luks_mode: "assert"       # assert | enroll | data_volume
ltz_tpm_luks_require_tpm: true    # false on lab VMs without vTPM
ltz_tpm_luks_passphrase: ""       # vault / -e only — never commit
ltz_tpm_luks_pcrs: "0+2+4+7"
```

Lab inventory defaults to `data_volume` + `require_tpm: false` for disposable VMs.

---

## 3. Ops checks

```bash
sudo /usr/local/lib/ltz/ltz-tpm-luks-status.sh
cat /var/lib/ltz-trust/disk-encryption.json
# root LUKS?
findmnt -n -o SOURCE /
sudo cryptsetup status <mapper>   # if /dev/mapper/*
# TPM slots
sudo systemd-cryptenroll /dev/sdX
```

---

## 4. Intune

`client/intune/discovery.sh` emits `disk_encrypted`.  
`client/intune/rules.json` requires it **true** alongside attested + ticket_fresh.

---

## 5. Recovery

- Keep a **recovery key / passphrase** escrowed offline for every LUKS volume.  
- TPM PCR changes (firmware update) may require re-enroll with passphrase.  
- Do not remove passphrase slot until recovery process is proven.
