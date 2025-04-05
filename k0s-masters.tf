# Create LXC Control Plane
locals {
  master_hostname = try(coalesce(var.masters.hostname), "${var.config.name}-master")
  master_assignments = [
    for i in range(var.masters.count) : {
      index     = i
      hostname  = "${local.master_hostname}-${i + 1}"
      address   = "${cidrhost(var.config.ip_subnet, local.ip_offset + i)}/${local.cidr_suffix}"
      ip        = split("/", "${cidrhost(var.config.ip_subnet, local.ip_offset + i)}/${local.cidr_suffix}")[0]
      gateway   = var.config.gateway
      node_name = var.proxmox.nodes[i % length(var.proxmox.nodes)]
    }
  ]
}

resource "proxmox_virtual_environment_container" "master" {
  for_each = {
    for master in local.master_assignments : master.hostname => master
  }

  description = "Master Node"

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
    architecture = "amd64"
    cores        = var.masters.cores
    units        = 1024
  }

  memory {
    dedicated = var.masters.memory
    swap      = 0
  }

  network_interface {
    enabled  = true
    firewall = false
    bridge   = var.masters.bridge
    name     = var.masters.network
  }

  disk {
    datastore_id = var.masters.datastore_id
    size         = var.masters.disk_size
  }

  operating_system {
    template_file_id = proxmox_virtual_environment_download_file.master[each.value.node_name].id
    type             = local.distro
  }

  startup {
    order      = "3"
    up_delay   = "0"
    down_delay = "0"
  }

  tags         = ["k8s", "master"]
  unprivileged = false

  features {
    nesting = true
  }
}

# Configure for k0s
resource "null_resource" "configure" {
  for_each = {
    for k, v in proxmox_virtual_environment_container.master : k => v
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
    host        = each.value.node_name
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
