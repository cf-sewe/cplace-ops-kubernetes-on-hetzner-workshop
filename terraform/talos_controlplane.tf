##
# Talos control-planes configuration

resource "talos_machine_configuration_controlplane" "controlplane" {
  cluster_name = var.talos_cluster_name
  # TODO should be DNS entry with ipv4/ipv6
  cluster_endpoint = format("https://[%s]:6443", hcloud_load_balancer.controlplane.ipv6)
  machine_secrets  = talos_machine_secrets.cluster.machine_secrets
  docs_enabled     = false
  examples_enabled = false
}

resource "talos_machine_configuration_apply" "controlplane" {
  for_each              = hcloud_server.controlplane
  talos_config          = talos_client_configuration.cluster.talos_config
  machine_configuration = talos_machine_configuration_controlplane.controlplane.machine_config
  endpoint              = each.value.ipv6_address
  node                  = each.value.ipv6_address
  config_patches = [
    templatefile("${path.module}/talos/patch.yml.tpl", {
      hostname  = each.value.name
      dnsdomain = format("%s.local", var.talos_cluster_name)
    })
  ]
}
