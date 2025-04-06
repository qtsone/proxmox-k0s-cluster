variable "config" {
  description = "Cluster Configuration"
  type = object({
    # (Optional) Provide cluster name
    name = optional(string, "k0s")

    # (Optional) SSH Username
    username = optional(string, "root")

    # (Required) SSH Public Key
    public_key = string

    # (Required) SSH Private Key
    private_key      = string
    private_key_path = optional(string, "~/.ssh/id_rsa")

    # (Optional) Timezone
    timezone = optional(string, "Europe/Berlin")

    # Network Configuration
    ip_subnet = optional(string, "192.168.1.0/24")
    gateway   = optional(string, "192.168.1.1")
    ip_offset = optional(number, 10)
  })
}

variable "proxmox" {
  description = "Cluster Configuration"
  type = object({
    nodes        = list(string)
    datastore_id = optional(string, "local")
  })
}

variable "os" {
  description = "OS Configuration"
  type = object({
    distro  = optional(string)
    version = optional(string)
  })
  default = {}
  validation {
    condition     = can(regex("(debian|ubuntu)", var.os.distro))
    error_message = "os.distro must be either 'debian' or 'ubuntu'"
  }
}

variable "k0s" {
  description = "k0s Configuration"
  type = object({
    config = optional(object({
      apiVersion = optional(string)
      kind       = optional(string)
      metadata = optional(object({
        name = optional(string)
      }))
      spec = optional(object({
        konnectivity = optional(object({
          adminPort = optional(number, 8133)
          agentPort = optional(number, 8132)
        }))
      }))
    }))
  })
  default = {}
}

variable "installFlags" {
  description = "(optional) Control Plane install flags"
  type        = list(string)
  default     = ["--disable-components metrics-server"]
}

variable "controllers" {
  description = "Configuration for controller nodes"
  type = object({
    # (Required) Number of controller nodes
    count = optional(number, 3)

    # "(Optional) Deployment type for controller nodes: 'lxc' (default) or 'vm'"
    deployment_type = optional(string, "lxc")

    # (Optional) If enabled, Controller nodes also act as workers
    worker = optional(bool, false)

    # (Optional) Hostname prefix
    hostname = optional(string, "")

    # Compute
    cpu_arch    = optional(string, "amd64")
    cpu_sockets = optional(number, 1)
    cpu_cores   = optional(number, 4)
    cpu_units   = optional(number, 100)
    memory      = optional(number, 4096)
    hugepages   = optional(number, null)

    # Disk
    datastore_id = optional(string, "local")
    disk_size    = optional(number, 10)

    # Optional MountPoints
    mounts = optional(list(object({
      src_path      = string
      dst_path      = string
      size          = optional(string, null)
      acl           = optional(bool, null)
      backup        = optional(bool, false)
      replicate     = optional(bool, false)
      shared        = optional(bool, false)
      quota         = optional(bool, false)
      mount_options = optional(list(string), [])
    })), [])

    # (Optional) Network Configuration
    bridge  = optional(string, "vmbr0")
    network = optional(string, "eth0")

    # (Optional) Define packages
    packages = optional(list(string), [])
    commands = optional(list(string), [])
    files = optional(list(object({
      path    = string
      content = string
    })), [])
  })
  validation {
    condition     = can(regex("(lxc|vm)", var.controllers.deployment_type))
    error_message = "deployment_type must be either 'lxc' or 'vm'"
  }
}

variable "workers" {
  description = "Configuration for worker nodes"
  type = object({
    # (Required) Number of worker nodes
    count = optional(number, 3)

    # "(Optional) Deployment type for worker nodes: 'vm' (default) or 'lxc'"
    deployment_type = optional(string, "vm")

    # (Optional) Hostname prefix
    hostname = optional(string, "")

    # Compute
    cpu_arch    = optional(string, "amd64")
    cpu_sockets = optional(number, 1)
    cpu_cores   = optional(number, 4)
    cpu_units   = optional(number, 100)
    memory      = optional(number, 10240)
    hugepages   = optional(number, null)

    # Disk
    datastore_id = optional(string, "local")
    disk_size    = optional(number, 100)

    # Optional MountPoints
    mounts = optional(list(object({
      src_path      = string
      dst_path      = string
      size          = optional(string, null)
      acl           = optional(bool, null)
      backup        = optional(bool, false)
      replicate     = optional(bool, false)
      shared        = optional(bool, false)
      quota         = optional(bool, false)
      mount_options = optional(list(string), [])
    })), [])

    # (Optional) Network Configuration
    bridge  = optional(string, "vmbr0")
    network = optional(string, "eth0")

    # (Optional) Define packages
    packages = optional(list(string), ["qemu-guest-agent"])
    commands = optional(list(string), ["systemctl enable qemu-guest-agent", "systemctl start qemu-guest-agent"])
    files = optional(list(object({
      path    = string
      content = string
    })), [])
  })
  validation {
    condition     = can(regex("(lxc|vm)", var.workers.deployment_type))
    error_message = "deployment_type must be either 'lxc' or 'vm'"
  }
}

variable "ha" {
  description = "(Optional) Control plane HA. More info: https://docs.k0sproject.io/stable/high-availability/"
  type = object({
    enabled                  = optional(bool, false)
    load_balancer_ip_address = optional(string)
  })
  default = {
    enabled = false
  }
}

variable "nllb" {
  description = "(Optional) Node Local Load Balancing. More info: https://docs.k0sproject.io/stable/nllb/"
  type = object({
    enabled = optional(bool, false)
  })
  default = {
    enabled = false
  }
}

variable "cplb" {
  description = "(Optional) Control Plane Load Balancing. More info: https://docs.k0sproject.io/stable/cplb/"
  type = object({
    enabled    = optional(bool, false)
    virtual_ip = optional(string, null)
    auth_pass  = optional(string, null)
  })
  default = {
    enabled = false
  }
}
