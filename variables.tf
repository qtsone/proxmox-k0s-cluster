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

variable "masters" {
  description = "Configuration for master nodes"
  type = object({
    # (Required) Number of master nodes
    count = optional(number, 3)

    # (Optional) Hostname prefix
    hostname = optional(string, "")

    # Compute
    cores  = optional(number, 4)
    memory = optional(number, 4096)

    # Disk
    datastore_id = optional(string, "local")
    disk_size    = optional(number, 10)

    # (Optional) Network Configuration
    bridge  = optional(string, "vmbr0")
    network = optional(string, "eth0")
  })
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

variable "workers" {
  description = "Configuration for worker nodes"
  type = object({
    # (Required) Number of worker nodes
    count = optional(number, 3)

    # (Optional) Hostname prefix
    hostname = optional(string, "")

    # Compute
    cores     = optional(number, 4)
    memory    = optional(number, 10240)
    hugepages = optional(number, null)

    # Disk
    datastore_id = optional(string, "local")
    disk_size    = optional(number, 100)

    # (Optional) Network Configuration
    bridge = optional(string, "vmbr0")

    # (Optional) Define packages
    packages = optional(list(string), ["qemu-guest-agent"])
    commands = optional(list(string), ["systemctl enable qemu-guest-agent", "systemctl start qemu-guest-agent"])
  })
}
