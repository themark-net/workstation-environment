output "vm_ids" {
  value = { for k, v in proxmox_virtual_environment_vm.lab : k => v.vm_id }
}

output "vm_names" {
  value = { for k, v in proxmox_virtual_environment_vm.lab : k => v.name }
}

output "ipv4" {
  value = {
    for k, v in proxmox_virtual_environment_vm.lab :
    k => try(v.ipv4_addresses[1][0], try(v.ipv4_addresses[0][0], ""))
  }
}

output "lab_user" {
  value = var.lab_user
}

output "dns_domain" {
  value = var.dns_domain
}
