# Download Images
resource "proxmox_virtual_environment_download_file" "lxc" {
  for_each = (
    var.controllers.deployment_type == "lxc" || var.workers.deployment_type == "lxc"
  ) ? toset(var.proxmox.nodes) : toset([])

  content_type = "vztmpl"
  datastore_id = var.proxmox.datastore_id
  node_name    = each.key
  url          = local.lxc_url
}

resource "proxmox_virtual_environment_download_file" "vm" {
  for_each = (
    var.controllers.deployment_type == "vm" || var.workers.deployment_type == "vm"
  ) ? toset(var.proxmox.nodes) : toset([])

  content_type = "iso"
  datastore_id = var.proxmox.datastore_id
  node_name    = each.key
  url          = local.iso_url
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
