locals {
  controllers_enabled = var.controllers.count > 0 ? true : false
  workers_enabled     = var.workers.count > 0 ? true : false

  # Determine deployment types
  deployment_type_controller = local.controllers_enabled ? try(coalesce(var.controllers.deployment_type), "lxc") : null
  deployment_type_worker     = local.workers_enabled ? try(coalesce(var.workers.deployment_type), "vm") : null

  download_lxc = (local.deployment_type_controller == "lxc" || local.deployment_type_worker == "lxc") ? true : false
  download_vm  = (local.deployment_type_controller == "vm" || local.deployment_type_worker == "vm") ? true : false
}

# Download Images
resource "proxmox_virtual_environment_download_file" "lxc" {
  for_each = local.download_lxc ? toset(var.proxmox.nodes) : toset([])

  content_type        = "vztmpl"
  datastore_id        = var.proxmox.datastore_id
  node_name           = each.key
  url                 = local.lxc_url
  overwrite           = true
  overwrite_unmanaged = true
}

resource "proxmox_virtual_environment_download_file" "vm" {
  for_each = local.download_vm ? toset(var.proxmox.nodes) : toset([])

  content_type        = "iso"
  datastore_id        = var.proxmox.datastore_id
  node_name           = each.key
  url                 = local.iso_url
  overwrite           = true
  overwrite_unmanaged = true
}

# Configure k0sctl
resource "local_file" "k0sctl" {
  content  = local.k0sctl_config
  filename = "${path.cwd}/k0sctl.yaml"
}

# Confighure HAProxy
resource "local_file" "haproxy" {
  count    = var.ha.enabled ? 1 : 0
  content  = local.haproxy_config
  filename = "${path.cwd}/haproxy.cfg"
}
