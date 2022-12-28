variable "hcloud_token" {
  sensitive   = true
  description = "Hetzner Cloud API Token"
}

variable "hcloud_environment" {
  description = "Name of the Hetzner Cloud project (environment). Must be unique within the Hetzner Cloud account."
}

variable "hcloud_datacenter" {
  default     = "fsn1"
  description = "Hetzner Cloud location. You can list possible locations with 'hcloud location list'"
}

variable "hcloud_datacenter_backup" {
  default     = "nbg1"
  description = "Hetzner Cloud backup location."
}

# Company IP addresses (including VPN endpoint)
# see https://base.cplace.io/pages/1imokqmrbh1to1p3tk2htfead8/WAN
variable "company_ips" {
  type        = set(string)
  description = "Company IPs for restriction of management access"
  default = [
    "80.81.14.141/32",   # Alte Hopfenpost (M5)
    "62.245.186.106/32", # Neue Hopfenpost
    "212.114.227.134/32" # Alte Hopfenpost
  ]
}

variable "bootstrap_public_keys" {
  description = "Public SSH keys of administrators added to the root authorized_keys. Login is only possible before hardening took place."
  type = map(object({
    public_key = string
  }))
  default = {
    "sebastian.weitzel@collaboration-factory" = {
      public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH4jw2Rt/3d0YuexTj0YEuV1VHcfK5XRH+HSHfw2JGCY"
    }
    "bartu.basman@collaboration-factory.de" = {
      public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILUJLtP6eziTIK1rH7Ioy0ajcW7OEB9mOkCbgilEHLvZ"
    }
    "jakob.leitmeir@collaboration-factory.de" = {
      public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJjmSeTp9WpT6aWeiGEOpT/OilB00Ct3+6Z4m9d7S5xW"
    }
  }
}

variable "talos_cluster_name" {
  default     = "training"
  description = "Talos Cluster Name"
}

variable "k8s_node_placement_group_count" {
  default     = 2
  description = "Defines the number of placement groups to create for k8s nodes."
}

variable "k8s_nodes" {
  description = "hcloud servers used for k8s control and worker nodes"
  type = map(object({
    name        = string
    location    = optional(string, "hel1")
    server_type = optional(string, "cpx31")
    node_type   = optional(string, "worker")
    pgroup      = optional(number, 0)
  }))
  default = {
    "1" = {
      name        = "control-1"
      server_type = "cpx21"
      node_type   = "controlplane"
      pgroup      = 0
    }
    "2" = {
      name        = "control-2"
      server_type = "cpx21"
      node_type   = "controlplane"
      pgroup      = 0
    }
    "3" = {
      name        = "control-3"
      server_type = "cpx21"
      node_type   = "controlplane"
      pgroup      = 0
    }
    "4" = {
      name   = "worker-1"
      pgroup = 1
    }
    "5" = {
      name   = "worker-2"
      pgroup = 1
    }
  }
}
