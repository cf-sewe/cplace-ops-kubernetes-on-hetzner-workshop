resource "talos_machine_secrets" "cluster" {}

resource "talos_client_configuration" "cluster" {
  cluster_name    = var.talos_cluster_name
  endpoints       = [for s in hcloud_server.controlplane : s.ipv4_address]
  nodes           = [for s in hcloud_server.controlplane : s.ipv4_address]
  machine_secrets = talos_machine_secrets.cluster.machine_secrets
}

resource "talos_machine_configuration_controlplane" "controlplane" {
  cluster_name = var.talos_cluster_name
  # TODO should be DNS entry with ipv4/ipv6
  cluster_endpoint = format("https://%s:6443", hcloud_load_balancer.controlplane.ipv4)
  machine_secrets  = talos_machine_secrets.cluster.machine_secrets
  docs_enabled     = false
  examples_enabled = false
  config_patches = [
    templatefile("${path.module}/talos/controlplane.patch.yml.tpl", {
      dnsdomain = format("%s.local", var.talos_cluster_name)
    })
  ]
}
