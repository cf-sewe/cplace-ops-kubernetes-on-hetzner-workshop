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
  - encoding: base64
    defer: true
    content: "${ansible_private_key}"
    owner: "ansible:ansible"
    path: "/home/ansible/.ssh/id_rsa"
    permissions: "0400"
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
runcmd:
  - [chown, -R, "ansible:ansible", "/home/ansible"]
