output "k0sctl_config" {
  value = yamlencode(local.k0sctl_config)
}

output "iso_url" {
  value = local.iso_url
}

output "lxc_url" {
  value = local.lxc_url
}

output "masters" {
  value = local.master_assignments
}

output "workers" {
  value = local.worker_assignments
}
