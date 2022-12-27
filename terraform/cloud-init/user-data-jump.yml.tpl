---
timezone: "Europe/Berlin"
ssh_pwauth: false
ssh_genkeytypes: [rsa, ed25519]
users:
  - name: ansible
    lock_passwd: true
    ssh-authorized-keys:
      - "${ansible_public_key} Ansible key managed by Terraform"
    shell: "/bin/bash"
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
write_files:
  - path: "/home/ansible/.ssh/id_rsa"
    encoding: base64
    content: "${ansible_private_key}"
    owner: "ansible:ansible"
    permissions: "0400"
    defer: false
  - path: "/home/ansible/.talos/config"
    encoding: base64
    content: "${talosconfig}"
    owner: "ansible:ansible"
    permissions: "0400"
    defer: false
packages:
  - ansible-core
  - bzip2
  - curl
  - git-core
  - jq
  - mc
  - python3-dns
  - unzip
  - zip
package_upgrade: true
package_reboot_if_required: true
