# Terraform

Terraform is used to automate and manage the deployment of the Kubernetes infrastructure within hcloud.

Note: The production Kubernetes cluster will likely be based on dedicated servers.
It may or may not be required to use Terraform in that scenario.

## Components

The following sections list the components covered by Terraform.

### Jump Server

The jump server is used as a bastion host.
It is the only external component permitted for communicating with the Kubernetes cluster.

The following tools are installed on the jump server:

- `kubectl` for managing the K8S cluster
- `talosctl` for managing the Talos OS
- `packer` for creating the Talos boot image

### Kubernetes Nodes

Terraform is used to deploy the Kubernetes Nodes that are running in the hcloud.

Note: Dedicated servers are not managed by Terraform.

### Load Balancer

The hcloud load balancer will be used for the K8S API (controlplane).
It will also be used for exposing the applications running within K8S.

## Updating Terraform Modules

The Terraform module versions are defined in `.terraform.lock.hcl` which is checked into the GIT repository.
To update the module versions, please use the following command:

```bash
terraform init -upgrade
```

Afterward, check the changed files back into the GIT repository.

## Findings

- The hcloud load balancer can only communicate to the backend servers
  if the servers have a public IPv4
  or they are in the same private network.
- If container download from gcr.io is blocked with HTTP 403 Forbidden, it means the IP of the server is (temporarily?) blocked.
  This can be a blocker for the bootstrapping procedure.
- A larger MTU size (jumbo frames) of 9000 instead of the default 1500 would improve network performance and reduce system load.
  However, Hetzner doesn't seem to support it.
