# SSH public key for bootstrapping (also avoids root password generation)
# Note: will be removed by Ansible
resource "hcloud_ssh_key" "bootstrap_public_keys" {
  for_each   = var.bootstrap_public_keys
  name       = each.key
  public_key = each.value.public_key
}
