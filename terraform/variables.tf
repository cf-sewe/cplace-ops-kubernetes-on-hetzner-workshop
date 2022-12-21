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

variable "talos_version" {
  default     = "1.2.8"
  description = "Talos OS version to use for Packer"
}
