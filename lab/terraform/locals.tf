locals {
  vms = {
    ca    = { name = "ltz-lab-ca", cores = 2, memory = 2048, disk = 20, vtpm = false, vmid = var.vm_start_id }
    rp    = { name = "ltz-lab-rp", cores = 2, memory = 2048, disk = 20, vtpm = false, vmid = var.vm_start_id + 1 }
    ws1   = { name = "ltz-lab-ws1", cores = 4, memory = 4096, disk = 40, vtpm = true, vmid = var.vm_start_id + 2 }
    svc_a = { name = "ltz-lab-svc-a", cores = 1, memory = 1024, disk = 10, vtpm = false, vmid = var.vm_start_id + 3 }
    svc_b = { name = "ltz-lab-svc-b", cores = 1, memory = 1024, disk = 10, vtpm = false, vmid = var.vm_start_id + 4 }
  }
  spire_vm = {
    spire = { name = "ltz-lab-spire", cores = 2, memory = 2048, disk = 20, vtpm = false, vmid = var.vm_start_id + 5 }
  }
  all_vms = merge(local.vms, var.enable_spire_vm ? local.spire_vm : {})
}
