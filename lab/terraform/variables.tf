variable "proxmox_endpoint" {
  type = string
}

variable "proxmox_api_token" {
  type      = string
  sensitive = true
}

variable "proxmox_insecure" {
  type    = bool
  default = true
}

variable "proxmox_ssh_username" {
  type    = string
  default = "root"
}

variable "proxmox_node" {
  type = string
}

variable "template_vm_id" {
  type = number
}

variable "datastore_id" {
  type    = string
  default = "local-lvm"
}

variable "snippet_datastore_id" {
  type    = string
  default = "local"
}

variable "bridge" {
  type    = string
  default = "vmbr0"
}

variable "ssh_public_key" {
  type = string
}

variable "lab_user" {
  type    = string
  default = "ltz"
}

variable "dns_domain" {
  type    = string
  default = "ltz.lab"
}

variable "enable_spire_vm" {
  type    = bool
  default = true
}

variable "vm_ip_cidr_map" {
  type    = map(string)
  default = {}
}

variable "gateway" {
  type    = string
  default = ""
}

variable "vm_start_id" {
  type    = number
  default = 8800
}
