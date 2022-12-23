output "jump_server_ipv4" {
  value       = hcloud_server.jump.ipv4_address
  description = "IPv4 address of the jump server"
}

output "ansible_ssh_public_key" {
  value       = tls_private_key.ansible_ssh.public_key_openssh
  description = "Public SSH key for Ansible"
}

output "talosconfig" {
  value     = talos_client_configuration.cluster.talos_config
  sensitive = true
}

output "kubeconfig" {
  value     = talos_cluster_kubeconfig.cluster.kube_config
  sensitive = true
}
