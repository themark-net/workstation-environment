#!/usr/bin/env bash
# Run ON a Proxmox node as root.
set -euo pipefail
VMID="${VMID:-9000}"
STORAGE="${STORAGE:-local-lvm}"
BRIDGE="${BRIDGE:-vmbr0}"
IMAGE_URL="${IMAGE_URL:-https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img}"
WORKDIR="${WORKDIR:-/var/lib/vz/template/iso}"
mkdir -p "$WORKDIR"
cd "$WORKDIR"
IMG="noble-server-cloudimg-amd64.img"
[[ -f "$IMG" ]] || wget -O "$IMG" "$IMAGE_URL"
qm destroy "$VMID" --purge 2>/dev/null || true
qm create "$VMID" --name ubuntu-24.04-cloud-template --memory 2048 --cores 2 --net0 "virtio,bridge=${BRIDGE}"
qm importdisk "$VMID" "$IMG" "$STORAGE"
qm set "$VMID" --scsihw virtio-scsi-single --scsi0 "${STORAGE}:vm-${VMID}-disk-0,discard=on,iothread=1"
qm set "$VMID" --boot order=scsi0
qm set "$VMID" --ide2 "${STORAGE}:cloudinit"
qm set "$VMID" --serial0 socket --vga serial0
qm set "$VMID" --agent enabled=1
qm set "$VMID" --ipconfig0 ip=dhcp
qm template "$VMID"
echo "Template VMID=$VMID ready"
