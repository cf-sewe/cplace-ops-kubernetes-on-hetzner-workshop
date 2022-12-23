##
# Load Balancer for Kubernetes API and Services

resource "hcloud_load_balancer" "controlplane" {
  name               = "controlplane"
  load_balancer_type = "lb11"
  location           = "fsn1"
}

resource "hcloud_load_balancer_service" "controlplane" {
  load_balancer_id = hcloud_load_balancer.controlplane.id
  listen_port      = "6443"
  destination_port = "6443"
  protocol         = "tcp"
}

resource "hcloud_load_balancer_target" "controlplane" {
  load_balancer_id = hcloud_load_balancer.controlplane.id
  type             = "label_selector"
  label_selector   = "type=controlplane"
}
