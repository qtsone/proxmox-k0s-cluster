locals {
  ubuntu_base_url = "https://cloud-images.ubuntu.com/releases"
  debian_base_url = "https://cloud.debian.org/images/cloud"

  distro  = try(coalesce(var.os.distro), "ubuntu")
  version = try(coalesce(var.os.version), local.distro == "ubuntu" ? "24.04" : "12")

  osname = local.distro == "debian" ? {
    10 = "buster"
    11 = "bullseye"
    12 = "bookworm"
    }[local.version] : {
    18.04 = "bionic"
    20.04 = "focal"
    22.04 = "jammy"
    24.04 = "noble"
  }[local.version]

  # Determine the base URL based on the distro
  base_url = {
    "ubuntu" = local.ubuntu_base_url
    "debian" = local.debian_base_url
  }[local.distro]

  # Format the download URL for ISO
  iso_url = {
    "ubuntu" = "${local.base_url}/${local.version}/release/ubuntu-${local.version}-server-cloudimg-amd64.img"
    "debian" = "${local.base_url}/${local.osname}/latest/debian-${local.version}-genericcloud-amd64.qcow2"
  }[local.distro]

  # Format the download URL for LXC
  lxc_url = {
    "ubuntu" = "http://download.proxmox.com/images/system/ubuntu-${local.version}-standard_${local.version}-2_amd64.tar.zst"
    "debian" = "http://download.proxmox.com/images/system/debian-${local.version}-standard_${local.version}.7-1_amd64.tar.zst"
  }[local.distro]

  k0s = {
    config = {
      apiVersion = try(coalesce(var.config.apiVersion), "k0s.k0sproject.io/v1beta1")
      kind       = try(coalesce(var.config.kind), "Cluster")
      metadata = {
        name = try(coalesce(var.config.metadata.name), var.config.name)
      }
      spec = {
        konnectivity = {
          adminPort = try(coalesce(var.config.spec.konnectivity.adminPort), 8133)
          agentPort = try(coalesce(var.config.spec.konnectivity.agentPort), 8132)
        }
      }
    }
  }

  cidr_suffix      = split("/", var.config.ip_subnet)[1]
  ip_offset        = try(var.config.ip_offset, 10)
  worker_ip_offset = local.ip_offset + var.controllers.count

  k0sctl_config = templatefile("${path.module}/templates/k0sctl.tftpl", {
    name              = var.config.name
    controllers       = [for m in local.controller_assignments : m]
    workers           = [for w in local.worker_assignments : w]
    controller_role   = var.controllers.worker ? "controller+worker" : "controller"
    controller_worker = var.controllers.worker
    username          = var.config.username
    private_key_path  = var.config.private_key_path
    k0s               = local.k0s
    ha                = var.ha
    nllb              = var.nllb
    cplb              = var.cplb
    installFlags      = var.installFlags
  })

  haproxy_config = templatefile("${path.module}/templates/haproxy.tftpl", {
    name             = var.config.name
    controllers      = [for m in local.controller_assignments : m]
    workers          = [for w in local.worker_assignments : w]
    username         = var.config.username
    private_key_path = var.config.private_key_path
    k0s              = local.k0s
    ha               = var.ha
    nllb             = var.nllb
    cplb             = var.cplb
    installFlags     = var.installFlags
  })

  controller_packages = distinct(concat(var.controllers.packages, ["qemu-guest-agent"]))
  controller_commands = distinct(concat(var.controllers.commands, ["systemctl enable qemu-guest-agent", "systemctl start qemu-guest-agent"]))
  controller_files    = distinct(concat(var.controllers.files, []))

  worker_packages = distinct(concat(var.workers.packages, ["qemu-guest-agent"]))
  worker_commands = distinct(concat(var.workers.commands, ["systemctl enable qemu-guest-agent", "systemctl start qemu-guest-agent"]))
  worker_files    = distinct(concat(var.workers.files, []))
}
