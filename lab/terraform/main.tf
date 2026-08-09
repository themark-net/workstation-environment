resource "proxmox_virtual_environment_file" "user_data" {
  for_each     = local.all_vms
  content_type = "snippets"
  datastore_id = var.snippet_datastore_id
  node_name    = var.proxmox_node
  source_raw {
    file_name = "ltz-${each.key}-user-data.yaml"
    data = templatefile("${path.module}/../cloud-init/user-data.yaml.tftpl", {
      hostname       = each.value.name
      fqdn           = "${each.value.name}.${var.dns_domain}"
      lab_user       = var.lab_user
      ssh_public_key = var.ssh_public_key
      role           = each.key
    })
  }
}

resource "proxmox_virtual_environment_vm" "lab" {
  for_each        = local.all_vms
  name            = each.value.name
  node_name       = var.proxmox_node
  vm_id           = each.value.vmid
  description     = "LTZ lab role=${each.key}"
  tags            = ["ltz-lab", each.key]
  stop_on_destroy = true

  clone {
    vm_id = var.template_vm_id
    full  = true
  }

  agent { enabled = true }

  cpu {
    cores = each.value.cores
    type  = "host"
  }

  memory { dedicated = each.value.memory }

  disk {
    datastore_id = var.datastore_id
    interface    = "scsi0"
    size         = each.value.disk
    discard      = "on"
    iothread     = true
  }

  network_device {
    bridge = var.bridge
    model  = "virtio"
  }

  dynamic "tpm_state" {
    for_each = each.value.vtpm ? [1] : []
    content { version = "v2.0" }
  }

  initialization {
    # Cloud-init drive needs storage that supports content-type "images"
    # (local-lvm). Snippets (user-data YAML) stay on snippet_datastore_id.
    datastore_id      = var.datastore_id
    user_data_file_id = proxmox_virtual_environment_file.user_data[each.key].id
    dynamic "ip_config" {
      for_each = try(var.vm_ip_cidr_map[each.key], "") != "" ? [1] : []
      content {
        ipv4 {
          address = var.vm_ip_cidr_map[each.key]
          gateway = var.gateway != "" ? var.gateway : null
        }
      }
    }
  }

  operating_system { type = "l26" }

  # Cloud template defaults to serial VGA; workstations need a real display for
  # GNOME + Intune portal at the Proxmox console. Others keep std as well.
  vga {
    type = "std"
  }
}
