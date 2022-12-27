output "jump_server_ipv4" {
  value       = hcloud_server.jump.ipv4_address
  description = "IPv4 address of the jump server"
}

output "controlplane_ipv4" {
  value       = hcloud_server.controlplane.*.ipv4_address
  description = "IPv4 addresses of the controlplane nodes"
}

output "worker_ipv4" {
  value       = hcloud_server.worker.*.ipv4_address
  description = "IPv4 addresses of the worker nodes"
}

output "ansible_ssh_public_key" {
  value       = tls_private_key.ansible_ssh.public_key_openssh
  description = "Public SSH key for Ansible"
}

output "talosconfig" {
  value     = talos_client_configuration.cluster.talos_config
  sensitive = true
}

output "talossecrets" {
  value     = talos_machine_secrets.cluster.machine_secrets
  sensitive = true
}

output "talos_controlplane_config" {
  value     = talos_machine_configuration_controlplane.controlplane.machine_config
  sensitive = true
}

