# proxmox-k8s-cluster

<!-- BEGIN_TF_DOCS -->
[![semantic-release-badge]][semantic-release]

## Usage

Basic usage of this module:

---
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_proxmox"></a> [proxmox](#requirement\_proxmox) | ~> 0.74 |
## Resources

| Name | Type |
|------|------|
| [local_file.k0sctl](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [null_resource.configure](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [proxmox_virtual_environment_container.master](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_container) | resource |
| [proxmox_virtual_environment_download_file.master](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_download_file) | resource |
| [proxmox_virtual_environment_download_file.worker](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_download_file) | resource |
| [proxmox_virtual_environment_file.cloudconfig](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_file) | resource |
| [proxmox_virtual_environment_vm.worker](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm) | resource |
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_config"></a> [config](#input\_config) | Cluster Configuration | <pre>object({<br/>    # (Optional) Provide cluster name<br/>    name = optional(string, "k0s")<br/><br/>    # (Optional) SSH Username<br/>    username = optional(string, "root")<br/><br/>    # (Required) SSH Public Key<br/>    public_key = string<br/><br/>    # (Required) SSH Private Key<br/>    private_key      = string<br/>    private_key_path = optional(string, "~/.ssh/id_rsa")<br/><br/>    # (Optional) Timezone<br/>    timezone = optional(string, "Europe/Berlin")<br/><br/>    # Network Configuration<br/>    ip_subnet = optional(string, "192.168.1.0/24")<br/>    gateway   = optional(string, "192.168.1.1")<br/>    ip_offset = optional(number, 10)<br/>  })</pre> | n/a | yes |
| <a name="input_cplb"></a> [cplb](#input\_cplb) | (Optional) Control Plane Load Balancing. More info: https://docs.k0sproject.io/stable/cplb/ | <pre>object({<br/>    enabled    = optional(bool, false)<br/>    virtual_ip = optional(string, null)<br/>    auth_pass  = optional(string, null)<br/>  })</pre> | <pre>{<br/>  "enabled": false<br/>}</pre> | no |
| <a name="input_ha"></a> [ha](#input\_ha) | (Optional) Control plane HA. More info: https://docs.k0sproject.io/stable/high-availability/ | <pre>object({<br/>    enabled                  = optional(bool, false)<br/>    load_balancer_ip_address = optional(string)<br/>  })</pre> | <pre>{<br/>  "enabled": false<br/>}</pre> | no |
| <a name="input_installFlags"></a> [installFlags](#input\_installFlags) | (optional) Control Plane install flags | `list(string)` | <pre>[<br/>  "--disable-components metrics-server"<br/>]</pre> | no |
| <a name="input_k0s"></a> [k0s](#input\_k0s) | k0s Configuration | <pre>object({<br/>    config = optional(object({<br/>      apiVersion = optional(string)<br/>      kind       = optional(string)<br/>      metadata = optional(object({<br/>        name = optional(string)<br/>      }))<br/>      spec = optional(object({<br/>        konnectivity = optional(object({<br/>          adminPort = optional(number, 8133)<br/>          agentPort = optional(number, 8132)<br/>        }))<br/>      }))<br/>    }))<br/>  })</pre> | `{}` | no |
| <a name="input_masters"></a> [masters](#input\_masters) | Configuration for master nodes | <pre>object({<br/>    # (Required) Number of master nodes<br/>    count = optional(number, 3)<br/><br/>    # (Optional) Hostname prefix<br/>    hostname = optional(string, "")<br/><br/>    # Compute<br/>    cores  = optional(number, 4)<br/>    memory = optional(number, 4096)<br/><br/>    # Disk<br/>    datastore_id = optional(string, "local")<br/>    disk_size    = optional(number, 10)<br/><br/>    # (Optional) Network Configuration<br/>    bridge  = optional(string, "vmbr0")<br/>    network = optional(string, "eth0")<br/>  })</pre> | n/a | yes |
| <a name="input_nllb"></a> [nllb](#input\_nllb) | (Optional) Node Local Load Balancing. More info: https://docs.k0sproject.io/stable/nllb/ | <pre>object({<br/>    enabled = optional(bool, false)<br/>  })</pre> | <pre>{<br/>  "enabled": false<br/>}</pre> | no |
| <a name="input_os"></a> [os](#input\_os) | OS Configuration | <pre>object({<br/>    distro  = optional(string)<br/>    version = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_proxmox"></a> [proxmox](#input\_proxmox) | Cluster Configuration | <pre>object({<br/>    nodes        = list(string)<br/>    datastore_id = optional(string, "local")<br/>  })</pre> | n/a | yes |
| <a name="input_workers"></a> [workers](#input\_workers) | Configuration for worker nodes | <pre>object({<br/>    # (Required) Number of worker nodes<br/>    count = optional(number, 3)<br/><br/>    # (Optional) Hostname prefix<br/>    hostname = optional(string, "")<br/><br/>    # Compute<br/>    cores     = optional(number, 4)<br/>    memory    = optional(number, 10240)<br/>    hugepages = optional(number, null)<br/><br/>    # Disk<br/>    datastore_id = optional(string, "local")<br/>    disk_size    = optional(number, 100)<br/><br/>    # (Optional) Network Configuration<br/>    bridge = optional(string, "vmbr0")<br/><br/>    # (Optional) Define packages<br/>    packages = optional(list(string), ["qemu-guest-agent"])<br/>    commands = optional(list(string), ["systemctl enable qemu-guest-agent", "systemctl start qemu-guest-agent"])<br/>  })</pre> | n/a | yes |
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_iso_url"></a> [iso\_url](#output\_iso\_url) | n/a |
| <a name="output_k0sctl_config"></a> [k0sctl\_config](#output\_k0sctl\_config) | n/a |
| <a name="output_lxc_url"></a> [lxc\_url](#output\_lxc\_url) | n/a |
| <a name="output_masters"></a> [masters](#output\_masters) | n/a |
| <a name="output_workers"></a> [workers](#output\_workers) | n/a |
---
[semantic-release-badge]: https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg
[conventional-commits]: https://www.conventionalcommits.org/
[semantic-release]: https://semantic-release.gitbook.io
[semantic-release-badge]: https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg
[vscode-conventional-commits]: https://marketplace.visualstudio.com/items?itemName=vivaxy.vscode-conventional-commits
<!-- END_TF_DOCS -->