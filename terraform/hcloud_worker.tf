##
# Talos worker Nodes

resource "hcloud_server" "worker" {
  for_each = {
    for k in keys(var.talos_nodes) :
    k => var.talos_nodes[k]
    if lookup(var.talos_nodes[k], "node_type", "other") == "worker"
  }
  name               = each.value.name
  backups            = false
  delete_protection  = false
  image              = data.hcloud_image.talos.id
  location           = each.value.location
  server_type        = each.value.server_type
  placement_group_id = hcloud_placement_group.k8s-nodes-spread[each.value.pgroup].id
  labels = {
    "type" = "worker"
  }
  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }
}

# All traffic toward internet is permitted.
resource "hcloud_firewall" "worker" {
  name = "worker"
  rule {
    description = "Allow inbound ICMP"
    direction   = "in"
    protocol    = "icmp"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  rule {
    description = "Allow inbound cluster internal TCP traffic"
    direction   = "in"
    protocol    = "tcp"
    port        = "any"
    source_ips = sort(concat(
      [format("%s/32", hcloud_server.jump.ipv4_address)],
      [for s in hcloud_server.controlplane : format("%s/32", s.ipv4_address)],
      [for s in hcloud_server.worker : format("%s/32", s.ipv4_address)]
    ))
  }
  rule {
    description = "Allow inbound cluster internal UDP traffic"
    direction   = "in"
    protocol    = "udp"
    port        = "any"
    source_ips = sort(concat(
      [for s in hcloud_server.controlplane : format("%s/32", s.ipv4_address)],
      [for s in hcloud_server.worker : format("%s/32", s.ipv4_address)]
    ))
  }
  rule {
    description = "Allow inbound HTTPS traffic (restrict to Cloudflare)"
    direction   = "in"
    protocol    = "tcp"
    port        = "443"
    source_ips  = "any"
  }
  apply_to {
    label_selector = "type=worker"
  }
}

# Note: if the firewall is configured too early, the config cannot be applied
resource "hcloud_firewall_attachment" "worker" {
  firewall_id     = hcloud_firewall.worker.id
  label_selectors = ["type=worker"]
}

# worker nodes get an additional hcloud volume
# it will be used to install Talos
resource "hcloud_volume" "volumes" {
  for_each          = hcloud_server.worker
  name              = "${each.value.name}-data"
  automount         = false
  delete_protection = false
  size              = var.talos_worker_volume_size
  server_id         = each.value.id
  depends_on        = [hcloud_server.worker]
}
