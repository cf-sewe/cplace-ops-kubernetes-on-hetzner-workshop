##
# Talos Controlplane Nodes

resource "hcloud_server" "controlplane" {
  for_each = {
    for k in keys(var.talos_nodes) :
    k => var.talos_nodes[k]
    if lookup(var.talos_nodes[k], "node_type", "other") == "controlplane"
  }
  name               = each.value.name
  backups            = false
  delete_protection  = false
  image              = data.hcloud_image.talos.id
  location           = each.value.location
  server_type        = each.value.server_type
  placement_group_id = hcloud_placement_group.k8s-nodes-spread[each.value.pgroup].id
  labels = {
    "type" = "controlplane"
  }
  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }
}

# All traffic toward internet is permitted.
resource "hcloud_firewall" "controlplane" {
  name = "controlplane"
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
    description = "Allow inbound private HTTPS traffic"
    direction   = "in"
    protocol    = "tcp"
    port        = "443"
    source_ips = sort(concat(
      [format("%s/32", hcloud_server.jump.ipv4_address)],
      [for s in hcloud_server.controlplane : format("%s/32", s.ipv4_address)]
    ))
  }
  rule {
    description = "Allow inbound Kubernetes API traffic from LB"
    direction   = "in"
    protocol    = "tcp"
    port        = "6443"
    source_ips  = [format("%s/32", hcloud_load_balancer.controlplane.ipv4)]
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
  apply_to {
    label_selector = "type=controlplane"
  }
}

# Note: if the firewall is configured too early, the config cannot be applied
resource "hcloud_firewall_attachment" "controlplane" {
  firewall_id     = hcloud_firewall.controlplane.id
  label_selectors = ["type=controlplane"]
}
