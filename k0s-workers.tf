# Configure VM Worker Nodes
locals {
  worker_hostname = try(coalesce(var.workers.hostname), "${var.config.name}-worker")
  worker_assignments = [
    for i in range(var.workers.count) : {
      index     = i
      hostname  = "${local.worker_hostname}-${i + 1}"
      address   = "${cidrhost(var.config.ip_subnet, local.worker_ip_offset + i)}/${local.cidr_suffix}"
      ip        = split("/", "${cidrhost(var.config.ip_subnet, local.worker_ip_offset + i)}/${local.cidr_suffix}")[0]
      gateway   = var.config.gateway
      node_name = var.proxmox.nodes[i % length(var.proxmox.nodes)]
    }
  ]
}

resource "proxmox_virtual_environment_file" "cloudconfig" {
  for_each = {
    for worker in local.worker_assignments : worker.hostname => worker
  }

  content_type = "snippets"
  datastore_id = var.proxmox.datastore_id
  node_name    = each.value.node_name

  source_raw {
    data = <<-EOF
    #cloud-config
    hostname: ${each.key}
    timezone: ${var.config.timezone}
    users:
      - name: ${var.config.username}
        shell: /bin/bash
        ssh_authorized_keys:
          - ${trimspace(var.config.public_key)}
    package_update: true
    packages:
%{for pkg in var.workers.packages~}
      - ${pkg}
%{endfor~}
    runcmd:
%{for cmd in var.workers.commands~}
      - ${cmd}
%{endfor~}
      - echo "done" > /tmp/cloud-config.done
    EOF

    file_name = "${each.key}-cloud-config.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "worker" {
  for_each = {
    for worker in local.worker_assignments : worker.hostname => worker
  }

  depends_on = [proxmox_virtual_environment_file.cloudconfig]

  name      = each.key
  node_name = each.value.node_name
  tags      = ["k8s", "worker"]

  agent {
    enabled = true
  }

  cpu {
    cores   = var.workers.cores
    sockets = 1
    type    = "host"
    numa    = true
  }

  memory {
    dedicated = var.workers.memory
    hugepages = var.workers.hugepages
  }

  disk {
    datastore_id = var.workers.datastore_id
    file_id      = proxmox_virtual_environment_download_file.worker[each.value.node_name].id
    interface    = "scsi0"
    iothread     = false
    discard      = "on"
    size         = var.workers.disk_size
    ssd          = true
  }

  initialization {
    datastore_id = var.workers.datastore_id
    ip_config {
      ipv4 {
        address = each.value.address
        gateway = each.value.gateway
      }
    }

    user_data_file_id = proxmox_virtual_environment_file.cloudconfig[each.key].id
  }

  network_device {
    bridge = var.workers.bridge
  }

}
