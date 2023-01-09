#!/bin/bash
set -e

echo ">>> Installing kubectl"
v=$(curl -Ls https://dl.k8s.io/release/stable.txt)
curl -sLo /usr/local/bin/kubectl "https://dl.k8s.io/release/${v}/bin/linux/amd64/kubectl"
chmod 755 /usr/local/bin/kubectl
echo 'source <(/usr/local/bin/kubectl completion bash)' | sudo -nu ansible tee -a /home/ansible/.bashrc

echo ">>> Installing talosctl"
v=$(curl -s https://api.github.com/repos/siderolabs/talos/releases/latest | jq -r '.tag_name')
curl -sLo /usr/local/bin/talosctl "https://github.com/siderolabs/talos/releases/download/${v}/talosctl-linux-amd64"
chmod 755 /usr/local/bin/talosctl
echo 'source <(/usr/local/bin/talosctl completion bash)' | sudo -nu ansible tee -a /home/ansible/.bashrc

echo ">>> Installing packer"
dnf config-manager --add-repo "https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo"
dnf install -y packer

echo ">>> Installing helm"
curl -fsSL "https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3" | bash
echo 'source <(/usr/local/bin/helm completion bash)' | sudo -nu ansible tee -a /home/ansible/.bashrc

echo ">>> Installing cilium cli"
v=$(curl -Ls https://raw.githubusercontent.com/cilium/cilium-cli/master/stable.txt)
curl -fsSL --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${v}/cilium-linux-amd64.tar.gz
tar -C /usr/local/bin -xzf cilium-linux-amd64.tar.gz
rm cilium-linux-amd64.tar.gz
echo 'source <(/usr/local/bin/cilium completion bash)' | sudo -nu ansible tee -a /home/ansible/.bashrc

echo ">>> Final steps"
/usr/bin/sudo -nu ansible tee /home/ansible/.ssh/known_hosts <<EOT
# github.com:22 SSH-2.0-babeld-8eb00d7e
github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=
# github.com:22 SSH-2.0-babeld-8eb00d7e
github.com ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==
# github.com:22 SSH-2.0-babeld-8eb00d7e
github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
EOT

echo ">>> All done <<<"
