output "jump_server_ipv4" {
  value       = hcloud_server.jump.ipv4_address
  description = "IPv4 address of the jump server"
}
