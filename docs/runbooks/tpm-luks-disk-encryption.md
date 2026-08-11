# Runbook: TPM + LUKS disk encryption baseline (+ recovery escrow)

**Role:** `client/ansible/roles/ltz_tpm_luks`  
**Wired into:** `bootstrap-host.yml` when `ltz_enable_tpm_luks: true`  
**Compliance claim:** `disk_encrypted` (+ `recovery_escrowed` when escrow completes) via  
`/var/lib/ltz-trust/disk-encryption.json` → Intune discovery

---

## 1. Modes

| Mode | Use when | Effect |
|------|----------|--------|
| `assert` | Greenfield hosts installed with FDE | Verify LUKS root (or `ltz-secure` data vol); write status |
| `enroll` | Root already LUKS; bind TPM2 | `systemd-cryptenroll --tpm2-device=auto` (needs passphrase once) |
| `data_volume` | Lab / retrofit without re-install | Encrypted image/mapper at `/var/lib/ltz-secure` |

**This role does not re-encrypt an existing cleartext root.** Full-disk LUKS must be chosen at OS install (autoinstall/kickstart/image).

---

## 2. BitLocker vs LUKS (what we implemented)

| BitLocker (Windows) | LTZ Linux (`ltz_tpm_luks`) |
|---------------------|----------------------------|
| TPM protector | `systemd-cryptenroll --tpm2-device=auto` (PCR bind) |
| Recovery password | `systemd-cryptenroll --recovery-key` |
| Escrow to AD / Entra / Intune | **Ansible controller fetch** → `secrets/luks-escrow/<host>/` (gitignored) |
| Optional additional protectors | Optional `age` / `openssl` wrap of the escrow package |

**There is no built-in “escrow to Entra” for Linux LUKS** the way BitLocker has. The Ansible control node (or a vault it immediately re-uploads to) is the enterprise store.

---

## 3. Escrow is not Clevis

| Mechanism | What it does | Escrow? |
|-----------|--------------|---------|
| **TPM enroll** | Auto-unlock when PCRs match | No — local convenience |
| **Recovery key + Ansible fetch** | Break-glass key stored off-host | **Yes** (BitLocker analogue) |
| **Clevis + Tang** | Network-bound disk encryption (NBDE); disk unlocks if Tang server answers | **No** — availability unlock, not recovery archival |
| **Clevis + TPM2** | Clevis pin for TPM (similar class to systemd-cryptenroll) | Still not escrow |

Use **Clevis/Tang** only if you want *network-assisted unlock* (e.g. fleet reboots in a data center).  
Use **our escrow path** for *lost TPM / PCR change / disaster recovery* — same ops job as BitLocker recovery passwords.

The Ansible host that enables TPM can (and now does) **also** ensure a recovery slot and **pull** the package with `fetch`. That is the right place for escrow; Clevis does not replace it.

---

## 4. Vars

```yaml
ltz_enable_tpm_luks: true
ltz_tpm_luks_mode: "assert"       # assert | enroll | data_volume
ltz_tpm_luks_require_tpm: true    # false on lab VMs without vTPM
ltz_tpm_luks_passphrase: ""       # vault / -e only — never commit
ltz_tpm_luks_pcrs: "0+2+4+7"

# Recovery escrow (BitLocker-style)
ltz_tpm_luks_escrow_enable: true
ltz_tpm_luks_escrow_controller_dir: "{{ playbook_dir }}/../../../secrets/luks-escrow"
ltz_tpm_luks_escrow_wrap: none          # none | age | openssl
ltz_tpm_luks_escrow_pubkey_path: ""     # age recipients or openssl pubkey on host
ltz_tpm_luks_escrow_delete_local_after_fetch: true
ltz_tpm_luks_escrow_strict: false       # true = fail play if escrow fails
```

Lab inventory: `data_volume` + `require_tpm: false` for disposable VMs.

---

## 5. Flow (enroll + escrow)

```text
host LUKS volume
  ├─ slot: passphrase (bootstrap / break-glass local)
  ├─ slot: TPM2 (systemd-cryptenroll)     ← day-to-day unlock
  └─ slot: recovery key                   ← disaster
         └─ package JSON (optional age wrap)
                └─ ansible fetch → controller secrets/luks-escrow/<host>/
                       └─ ops copies to Vault / offline safe
                              └─ delete host plaintext
```

---

## 6. Ops checks

```bash
sudo /usr/local/lib/ltz/ltz-tpm-luks-status.sh
cat /var/lib/ltz-trust/disk-encryption.json
# recovery slots
sudo systemd-cryptenroll /dev/sdX
# controller (after bootstrap)
ls -la secrets/luks-escrow/
```

---

## 7. Recovery procedure

1. Obtain package for host from controller vault (`secrets/luks-escrow/<host>/` or age unwrap).  
2. Boot recovery media or drop to cryptsetup prompt.  
3. Unlock with **recovery key** (not TPM).  
4. After firmware/PCR change, re-enroll TPM:
   ```bash
   PASSWORD='<recovery-or-passphrase>' systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+2+4+7 /dev/sdX
   ```
5. Rotate recovery key if it was exposed; re-run role with escrow enabled.

---

## 8. Intune

`client/intune/discovery.sh` emits `disk_encrypted`.  
`rules.json` requires `disk_encrypted: true`.  
`recovery_escrowed` is recorded in `disk-encryption.json` for ops/attestor; add an Intune rule later if you want to **require** escrow for Compliant.

---

## 9. Production hardening (recommended)

1. `ltz_tpm_luks_escrow_wrap: age` with a dual-control recipient list.  
2. Controller `secrets/` on encrypted disk; never git.  
3. Pipeline step: push packages to HashiCorp Vault / Azure Key Vault immediately after fetch.  
4. `ltz_tpm_luks_escrow_strict: true` on production inventory.  
5. Access review: same people who can read BitLocker keys in Entra.
