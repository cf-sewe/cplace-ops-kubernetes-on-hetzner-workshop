##
# Jump Server

resource "tls_private_key" "ansible_ssh" {
  algorithm = "ED25519"
}

data "template_file" "user-data-jump" {
  template = file("${path.module}/cloud-init/user-data-jump.yml.tpl")
  vars = {
    ansible_public_key  = tls_private_key.ansible_ssh.public_key_openssh
    ansible_private_key = base64encode(tls_private_key.ansible_ssh.private_key_pem)
    talosconfig         = base64encode(talos_client_configuration.cluster.talos_config)
    talossecrets        = base64encode(talos_machine_secrets.cluster.machine_secrets)
  }
}

data "template_cloudinit_config" "jump-server" {
  gzip          = true
  base64_encode = true
  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.user-data-jump.rendered
  }
  part {
    content_type = "text/x-shellscript"
    content      = file("${path.module}/cloud-init/install-jump.sh")
  }
}

# All traffic toward internet is permitted.
resource "hcloud_firewall" "jump-server" {
  name = "jump-server"
  rule {
    direction = "in"
    protocol  = "icmp"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
    description = "Allow ICMP"
  }
  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "22"
    source_ips  = var.company_ips
    description = "Allow SSH from company IPs"
  }
}

resource "hcloud_server" "jump" {
  name              = "jump"
  backups           = false
  delete_protection = false
  image             = "rocky-9"
  location          = var.hcloud_datacenter
  keep_disk         = true
  server_type       = "cpx21"
  user_data         = data.template_cloudinit_config.jump-server.rendered
  ssh_keys          = [for public_key in hcloud_ssh_key.bootstrap_public_keys : public_key.id]
  firewall_ids      = [hcloud_firewall.jump-server.id]
  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }
}
