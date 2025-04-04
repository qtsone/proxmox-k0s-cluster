# Download Images
resource "proxmox_virtual_environment_download_file" "master" {
  for_each = toset(var.proxmox.nodes)

  content_type = "vztmpl"
  datastore_id = var.proxmox.datastore_id
  node_name    = each.key
  url          = local.lxc_url
}

resource "proxmox_virtual_environment_download_file" "worker" {
  for_each = toset(var.proxmox.nodes)

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
