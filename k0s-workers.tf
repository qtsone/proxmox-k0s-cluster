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
      node_name = var.proxmox.nodes[(i + var.controllers.count) % length(var.proxmox.nodes)]
    }
  ]
}

# VM Worker Nodes
resource "proxmox_virtual_environment_file" "worker_cloudconfig" {
  for_each = {
    for worker in local.worker_assignments : worker.hostname => worker
    if var.workers.deployment_type == "vm"
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
%{for pkg in local.worker_packages~}
      - ${pkg}
%{endfor~}
    runcmd:
%{for cmd in local.worker_commands~}
      - ${cmd}
%{endfor~}
      - echo "done" > /tmp/cloud-config.done
    write_files:
%{for item in local.controller_files~}
      - path: ${item.path}
        content: |
          ${item.content}
%{endfor~}
    EOF

    file_name = "${each.key}-cloud-config.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "worker" {
  for_each = {
    for worker in local.worker_assignments : worker.hostname => worker
    if var.workers.deployment_type == "vm"
  }

  name      = each.key
  node_name = each.value.node_name
  tags      = ["k8s", "worker"]

  agent {
    enabled = true
  }

  cpu {
    cores   = var.workers.cpu_cores
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
    file_id      = proxmox_virtual_environment_download_file.vm[each.value.node_name].id
    interface    = "scsi0"
    iothread     = false
    discard      = "on"
    size         = var.workers.disk_size
    ssd          = true
  }

  operating_system {
    type = "l26"
  }

  initialization {
    datastore_id = var.workers.datastore_id
    ip_config {
      ipv4 {
        address = each.value.address
        gateway = each.value.gateway
      }
    }

    user_data_file_id = proxmox_virtual_environment_file.worker_cloudconfig[each.key].id
  }

  network_device {
    bridge = var.workers.bridge
  }

}

# LXC Worker Nodes
resource "proxmox_virtual_environment_container" "worker" {
  for_each = {
    for worker in local.worker_assignments : worker.hostname => worker
    if var.workers.deployment_type == "lxc"
  }

  description = "Worker Node"

  node_name = each.value.node_name

  initialization {
    hostname = each.key

    ip_config {
      ipv4 {
        address = each.value.address
        gateway = each.value.gateway
      }
    }

    user_account {
      keys = [
        trimspace(var.config.public_key)
      ]
    }
  }

  console {
    enabled   = true
    type      = "tty"
    tty_count = 1
  }

  cpu {
    architecture = var.workers.cpu_arch
    cores        = var.workers.cpu_cores
    units        = var.workers.cpu_units
  }

  memory {
    dedicated = var.workers.memory
    swap      = 0
  }

  network_interface {
    enabled  = true
    firewall = false
    bridge   = var.workers.bridge
    name     = var.workers.network
  }

  disk {
    datastore_id = var.workers.datastore_id
    size         = var.workers.disk_size
  }

  dynamic "mount_point" {
    for_each = var.workers.mounts
    content {
      volume        = mount_point.value.src_path
      path          = mount_point.value.dst_path
      size          = try(mount_point.value.size, null)
      acl           = try(mount_point.value.acl, null)
      backup        = try(mount_point.value.backup, false)
      replicate     = try(mount_point.value.replicate, false)
      shared        = try(mount_point.value.shared, false)
      quota         = try(mount_point.value.quota, false)
      mount_options = try(mount_point.value.mount_options, false)
    }
  }

  operating_system {
    template_file_id = proxmox_virtual_environment_download_file.lxc[each.value.node_name].id
    type             = local.distro
  }

  startup {
    order      = "4"
    up_delay   = "0"
    down_delay = "0"
  }

  tags         = ["k8s", "worker"]
  unprivileged = false

  features {
    nesting = true
  }
}

# Configure for k0s
resource "null_resource" "configure_lxc_worker" {
  for_each = {
    for k, v in proxmox_virtual_environment_container.worker : k => v
    if var.workers.deployment_type == "lxc"
  }

  triggers = {
    instance     = each.key
    container_id = each.value.id
  }

  connection {
    type        = "ssh"
    user        = "root"
    password    = ""
    private_key = var.config.private_key
    host        = "${each.value.node_name}.${var.proxmox.domain}"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Configuring ${each.key}'...",
      # Extract LXC ID
      "LXC_ID=${each.value.id}",
      "echo \"LXC ID: $LXC_ID\"",

      "echo 'Performing host-level configurations...'",
      "echo 'lxc.apparmor.profile: unconfined' >> /etc/pve/lxc/$LXC_ID.conf",
      "echo 'lxc.cgroup2.devices.allow: a' >> /etc/pve/lxc/$LXC_ID.conf",
      "echo 'lxc.cap.drop:' >> /etc/pve/lxc/$LXC_ID.conf",
      "echo 'lxc.mount.auto: \"proc:rw sys:rw\"' >> /etc/pve/lxc/$LXC_ID.conf",

      "echo 'Running commands inside LXC container $LXC_ID...'",
      "echo 'Configuring /dev/kmsg...'",
      "pct exec $LXC_ID -- bash -c \"echo '[Unit]\nDescription=Create /dev/kmsg symlink\n\n[Service]\nType=oneshot\nExecStart=/bin/ln -sf /dev/console /dev/kmsg\nRemainAfterExit=yes\n\n[Install]\nWantedBy=multi-user.target' > /etc/systemd/system/kmsg.service\"",
      "pct exec $LXC_ID -- bash -c 'systemctl enable kmsg.service'",
      "pct stop $LXC_ID",
      "sleep 3",
      "pct start $LXC_ID",
    ]
  }
}
