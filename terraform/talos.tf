resource "talos_machine_secrets" "cluster" {}

resource "talos_client_configuration" "cluster" {
  cluster_name    = var.talos_cluster_name
  endpoints       = [for s in hcloud_server.controlplane : s.ipv4_address]
  machine_secrets = talos_machine_secrets.cluster.machine_secrets
}

# TODO is dependency on controlplane required?
resource "talos_machine_bootstrap" "cluster" {
  talos_config = talos_client_configuration.cluster.talos_config
  endpoint     = [for s in hcloud_server.controlplane : s.ipv4_address][0]
  node         = [for s in hcloud_server.controlplane : s.ipv4_address][0]
  depends_on   = [talos_machine_configuration_apply.controlplane]
}

resource "talos_cluster_kubeconfig" "cluster" {
  talos_config = talos_client_configuration.cluster.talos_config
  endpoint     = [for s in hcloud_server.controlplane : s.ipv4_address][0]
  node         = [for s in hcloud_server.controlplane : s.ipv4_address][0]
  depends_on   = [talos_machine_configuration_apply.controlplane]
}
