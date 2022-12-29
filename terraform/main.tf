# SSH public key for bootstrapping (also avoids root password generation)
# Note: will be removed by Ansible
resource "hcloud_ssh_key" "bootstrap_public_keys" {
  for_each   = var.bootstrap_public_keys
  name       = each.key
  public_key = each.value.public_key
}

data "hcloud_image" "talos" {
  with_selector = "os=talos"
}

resource "hcloud_placement_group" "k8s-nodes-spread" {
  count = var.talos_node_placement_group_count
  name  = "k8s-nodes-spread-${count.index}"
  type  = "spread"
}
