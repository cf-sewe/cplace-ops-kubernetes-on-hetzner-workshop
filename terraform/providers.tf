# Hetzner Cloud
provider "hcloud" {
  token = var.hcloud_token
}

provider "talos" {}
