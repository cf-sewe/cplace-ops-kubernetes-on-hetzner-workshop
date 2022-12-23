##
# Talos Controlplane Nodes

resource "hcloud_server" "controlplane" {
  for_each = {
    for k in keys(var.k8s_nodes) :
    k => var.k8s_nodes[k]
    if lookup(var.k8s_nodes[k], "node_type", "other") == "controlplane"
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
    source_ips = concat(
      [format("%s/32", hcloud_server.jump.ipv4_address)],
      [for s in hcloud_server.controlplane : format("%s/32", s.ipv4_address)]
    )
  }
  rule {
    description = "Allow inbound private Kubernetes API traffic"
    direction   = "in"
    protocol    = "tcp"
    port        = "6443"
    source_ips = concat(
      [
        format("%s/32", hcloud_server.jump.ipv4_address),
        format("%s/32", hcloud_load_balancer.controlplane.ipv4),
      ],
      [for s in hcloud_server.controlplane : format("%s/32", s.ipv4_address)]
    )
  }
  rule {
    description = "Allow inbound private Talos traffic"
    direction   = "in"
    protocol    = "tcp"
    port        = "50000-50001"
    source_ips = concat(
      [
        format("%s/32", hcloud_server.jump.ipv4_address),
        format("%s/32", hcloud_load_balancer.controlplane.ipv4),
      ],
      [for s in hcloud_server.controlplane : format("%s/32", s.ipv4_address)]
    )
  }
  rule {
    description = "Allow inbound private Kubernetes traffic (etcd server client API)"
    direction   = "in"
    protocol    = "tcp"
    port        = "2379-2380"
    source_ips  = [for s in hcloud_server.controlplane : format("%s/32", s.ipv4_address)]
  }
  rule {
    description = "Allow inbound private Kubernetes traffic (Kubelet API)"
    direction   = "in"
    protocol    = "tcp"
    port        = "10250"
    source_ips  = [for s in hcloud_server.controlplane : format("%s/32", s.ipv4_address)]
  }
  apply_to {
    label_selector = "type=controlplane"
  }
}

resource "hcloud_firewall_attachment" "controlplane" {
  firewall_id     = hcloud_firewall.controlplane.id
  label_selectors = ["type=controlplane"]
}
