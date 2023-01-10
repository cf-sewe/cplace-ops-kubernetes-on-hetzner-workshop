# Kubernetes Cluster Setup

In this session we deploy the Kubernetes cluster:

- [Kubernetes Cluster Setup](#kubernetes-cluster-setup)
  - [Required Variables](#required-variables)
  - [Talos Cluster Bootstrap Procedure](#talos-cluster-bootstrap-procedure)
  - [Deploying Cilium CNI](#deploying-cilium-cni)
  - [Deploying Traefik Reverse Proxy](#deploying-traefik-reverse-proxy)
    - [Create Traefik Default Certificate](#create-traefik-default-certificate)
    - [Exposing Hubble UI](#exposing-hubble-ui)
    - [Install and Expose Kubernetes Dashboard](#install-and-expose-kubernetes-dashboard)
  - [Cloudflare Load Balancer \& WAF](#cloudflare-load-balancer--waf)
  - [Deploying Pomerium Authentication Proxy](#deploying-pomerium-authentication-proxy)
  - [Deploying Portainer](#deploying-portainer)
  - [Troubleshooting Commands](#troubleshooting-commands)
    - [Talos](#talos)
    - [Kubernetes](#kubernetes)
  - [Noteworthy](#noteworthy)

## Required Variables

The following sections contain commands, that make use of environment-specific variables.

Adjust the following block with the proper data:

```bash
CLUSTER="training"                                       # Cluster name
LBIP="49.12.21.76"                                       # Loadbalancer IPv4 address
CPIPS="138.201.175.139,162.55.161.245,188.34.176.193"    # Controlplane IPv4 addresses
WIPS="159.69.116.222,167.235.205.180"                    # Worker IPv4 addresses
IFS=','
```

## Talos Cluster Bootstrap Procedure

1. Login to the jump server as user `ansible`, then change to the checked-out GIT repository.
2. Create configs for the control plane and worker nodes:

    ```bash
    # controlplane config
    talosctl gen config \
    --with-secrets ~/.talos/secrets.yaml ${CLUSTER} https://${LBIP}:6443 -t controlplane \
    --with-docs=false --with-examples=false --config-patch-control-plane @controlplane.patch.yaml
    # worker config
    talosctl gen config \
    --with-secrets ~/.talos/secrets.yaml ${CLUSTER} https://${LBIP}:6443 -t worker \
    --with-docs=false --with-examples=false --config-patch-worker @worker.patch.yaml
    ```

    Note that the `secret.yaml` has been created by Terraform.

3. Apply configs to the control plane nodes:

    ```bash
    for ip in $CPIPS; do
    echo "Apply config (controlplane): $ip"
    talosctl apply-config --insecure \
        --nodes ${ip} \
        --file controlplane.yaml
    done
    ```

4. Apply configs to the worker nodes:

    ```bash
    for ip in $WIPS; do
    echo "Apply config (worker): $ip"
    talosctl apply-config --insecure \
        --nodes ${ip} \
        --file worker.yaml
    done
    ```

5. Wait until all nodes are ready, either by using talosctl or the hcloud server console.

    ```bash
    # all nodes should be 'ready'
    talosctl get configstatus
    # all nodes should be 'booting'
    ```

    If a node config was not applied, the above commands might respond
    with `authentication handshake failed: x509: certificate signed by unknown authority`.
    Timeouts or "no such host" messages indicate invalid IPs.

6. Bootstrap the cluster using the first controlplane node:

    ```bash
    talosctl bootstrap -n "${CPIPS%%,*}"
    ```

7. Wait until the bootstrap procedure is complete.
   Either by checking the OS console output,
   or by using the `talosctl get machinestatus` command (this time also with worker IPs).

    ```console
    [ansible@jump ~]$ talosctl get machinestatus -n "${CPIPS},${WIPS}"
    NODE              NAMESPACE   TYPE            ID        VERSION   STAGE     READY
    159.69.116.222    runtime     MachineStatus   machine   15        booting   true
    138.201.175.139   runtime     MachineStatus   machine   17        booting   true
    188.34.176.193    runtime     MachineStatus   machine   15        booting   true
    162.55.161.245    runtime     MachineStatus   machine   12        booting   true
    167.235.205.180   runtime     MachineStatus   machine   13        booting   true
    ```

8. Generate the kubeconfig

    The `kubeconfig` file is used by `kubectl` required for managing the K8S cluster.

    ```bash
    talosctl kubeconfig -n "${CPIPS%%,*}"
    ```

## Deploying Cilium CNI

[Cilium](https://cilium.io/) is a high-performance [CNI](https://www.cni.dev/) for Kubernetes using the eBPF algorithm.
We will deploy it using the Helm chart, loosely following the Talos [documentation](https://www.talos.dev/v1.3/kubernetes-guides/network/deploying-cilium/).

Cilium is deployed with the `kube-proxy` replacement.
We also use Cilium as the Ingress controller and cert-manager for the LetsEncrypt certificate management.

The cluster is already prepared for Cilium:

- Talos `kube-proxy` is disabled
- Talos CNI is set to none
- Kernel parameters are tuned out of the box

As a prerequisite, configure the Cilium Helm repository (first time only):

```bash
helm repo add cilium https://helm.cilium.io/
helm repo update
```

Deploy Cilium via Helm:

```bash
# Ensure that the LBIP variable is set
helm install cilium cilium/cilium  \
  --values "002_K8S_Cluster_Setup/cilium/helm.values.yaml" \
  --namespace kube-system \
  --set k8sServiceHost="${LBIP}" \
  --set hubble.peerService.clusterDomain="${CLUSTER}.local"
```

Wait a few minutes, then check the cilium status using kubectl and/or the cilium CLI:

```bash
kubectl get pods -o wide -n kube-system
cilium status
```

## Deploying Traefik Reverse Proxy

Egress traffic to the K8S exposed services is routed through the Traefik reverse proxy.
Traefik is installed as a `DaemonSet` on each worker node.

Cloudflare load balancer is used to direct traffic to the worker nodes.
The Cloudflare origin certificate is configured in Traefik.

Configure the Helm repositories (only once):

```bash
helm repo add traefik https://helm.traefik.io/traefik
helm repo update
```

Install Traefik using Helm into the `kube-system` namespace:

```bash
helm install traefik traefik/traefik \
  --namespace kube-system \
  --values="002_K8S_Cluster_Setup/traefik/helm.values.yaml"
```

### Create Traefik Default Certificate

We configure the default Traefik TLS certificate to match the requirements of Cloudflare.

1. Edit the file `traefik/Secret_traefik-default-cert.yaml` and insert the "origin" certificate provided by Cloudflare.
2. Apply the `traefik/Secret_traefik-default-cert.yaml` file:

    ```bash
    kubectl apply -f "002_K8S_Cluster_Setup/traefik/Secret_traefik-default-cert.yaml"
    ```

3. Apply the `TLSStore_default.yaml` file:

    ```bash
    kubectl apply -f "002_K8S_Cluster_Setup/traefik/TLSStore_default.yaml"
    ```

### Exposing Hubble UI

Hubble is an UI for Cilium, and can show information about traffic flows.
To expose the Hubble UI, create an *IngressRoute*:

```bash
kubectl apply -f "002_K8S_Cluster_Setup/cilium/IngressRoute_hubble.yaml"
```

### Install and Expose Kubernetes Dashboard

Add Helm repository:

```bash
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
helm repo update
```

Install the dashboard via Helm:

```bash
helm install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard \
  --create-namespace --namespace kubernetes-dashboard \
  --values "002_K8S_Cluster_Setup/kubernetes-dashboard/helm.values.yaml"
```

Add *IngressRoute*:

```bash
kubectl apply -f "002_K8S_Cluster_Setup/kubernetes-dashboard/IngressRoute_kubernetes_dashboard.yaml"
```

Notes & TODO:

- We currently expose the dashboard with read-only permissions to the world.
  It must be secured for production use.

## Cloudflare Load Balancer & WAF

We are using Cloudflare as a load balancer and WAF for our Kubernetes cluster.

1. The hcloud DNS needs to point to Cloudflare, for example:

    ```raw
    *.training.cplace.cloud CNAME star.training.cplace.cloud.cdn.cloudflare.net.
    ```

2. Create the Cloudflare load balancer.
   Create service checks pointing to all the worker nodes port 443.
   Use equal load distribution and dynamic routing based on the lowest latency.

## Deploying Pomerium Authentication Proxy

To protect certain management UIs, the Pomerium auth proxy will be used.

## Deploying Portainer

Portainer can be used to manage Kubernetes resources more efficiently.

## Troubleshooting Commands

### Talos

Show available `get` targets.
This command also works if the nodes have not yet been bootstrapped.

```bash
talosctl get rd -i -n "${CPIPS%%,*}"
```

Show the known Talos cluster members.
This command connects to the specified node and outputs information for the whole cluster.

```bash
talosctl get members -n "${CPIPS%%,*}"
```

Show `etcd` members once the Talos bootstrap procedure is complete.

```bash
talosctl etcd members -n "${CPIPS%%,*}"
```

Show cluster health.

```bash
talosctl health --wait-timeout 5m -n "${CPIPS%%,*}"
```

Show node information (CPU/Load/Memory).

```bash
talosctl dashboard -n "${CPIPS%%,*}"
```

Shows the kernel log of the specified node.

```bash
talosctl dmesg -n "${CPIPS%%,*}"
```

Shows services of cluster nodes.

```bash
talosctl services
```

### Kubernetes

Show available versions of the specific Helm chart:

```bash
# helm search repo <reponame>/<chartname> --versions
helm search repo cilium/cilium --versions | head
```

| Component | Command                                                               | Description                               |
| :-------: | --------------------------------------------------------------------- | ----------------------------------------- |
|    K8S    | `kubectl get nodes -o wide`                                           | Lists the registered K8S nodes            |
|    K8S    | `kubectl get pods -o wide -A --field-selector spec.nodeName=worker-1` | Lists the pods running on specified node. |
kubectl describe pod kube-controller-manager-control-1 -n kube-system

## Noteworthy

- Traefik Let's Encrypt implementation does not support HA, therefore we have to use cert-manager
  https://doc.traefik.io/traefik/providers/kubernetes-ingress/#letsencrypt-support-with-the-ingress-provider
  We use the default certificate (self-signed) for now.
- The hcloud load balancer does not support UDP.
  UDP is a requirement for HTTP3, however, this is not so critical because we can use Cloudflare.
