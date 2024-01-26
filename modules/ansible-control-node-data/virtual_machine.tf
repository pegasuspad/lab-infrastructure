locals {
  data_vm_name = "lab-ansible-data"
  data_vmid    = lookup(local.assigned_vmids, local.data_vm_name, null)
  datastore    = "local-hdd"

  disk_config  = [
    {
      datastore_id = local.datastore
      label        = "ssh_keys"
      mountpoint   = "/var/lib/ansible"
      read_only    = true
      size         = 1
      ssd          = local.datastore == local.datastore_ssd
    }
  ]
}

module "disk_vm" {
  source = "github.com/pegasuspad/tf-modules.git//modules/proxmox-data-disk-vm?ref=main"

  name         = local.data_vm_name
  disk_config  = local.disk_config
  proxmox_node = local.proxmox_node
  tags         = ["devsecops", "lab"]
  vmid         = local.data_vmid
}

# save disk config to our github config repository
module "saved_config" {
  source     = "github.com/pegasuspad/tf-modules.git//modules/util-config-save?ref=main"
  data       = yamlencode({
    vmid           = module.disk_vm.vmid
    attached_disks = module.disk_vm.attached_disks
  })
  key        = "data-disk-vms/${module.disk_vm.name}.yml"
  repository = local.config_repository
}
