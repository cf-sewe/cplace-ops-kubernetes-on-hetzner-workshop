# Kubernetes Cluster Setup

In this session we deploy the Kubernetes cluster:

- [Kubernetes Cluster Setup](#kubernetes-cluster-setup)
  - [Required Variables](#required-variables)
  - [Talos Cluster Bootstrap Procedure](#talos-cluster-bootstrap-procedure)
  - [Deploying Cilium CNI](#deploying-cilium-cni)
    - [Preparing the Deployment Manifest](#preparing-the-deployment-manifest)
    - [Apply the Deployment Manifest](#apply-the-deployment-manifest)
  - [Troubleshooting Commands](#troubleshooting-commands)
  - [Talos](#talos)
  - [Kubernetes](#kubernetes)

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

1. Upload the files `controlplane.patch.yml` and `worker.patch.yml` to the jump server (user `ansible`).
2. Create configs for the controlplane and worker nodes:

```bash
# controlplane config
talosctl gen config \
--with-secrets ~/.talos/secrets.yml ${CLUSTER} https://${LBIP}:6443 -t controlplane \
--with-docs=false --with-examples=false --config-patch-control-plane @controlplane.patch.yml
# worker config
talosctl gen config \
--with-secrets ~/.talos/secrets.yml ${CLUSTER} https://${LBIP}:6443 -t worker \
--with-docs=false --with-examples=false --config-patch-worker @worker.patch.yml
```

3. Apply configs to the controlplane nodes:

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
talosctl get configstatus -n "${CPIPS},${WIPS}"
# all nodes should be 'booting'
talosctl get machinestatus -n "${CPIPS},${WIPS}"
```

If a node config was not applied, the above commands might respond
with `authentication handshake failed: x509: certificate signed by unknown authority`.
Timeouts or "no such host" messages indicate invalid IPs.

6. Bootstrap the cluster using the first controlplane node:

```bash
talosctl bootstrap -n "${CPIPS%%,*}"
```

This is the expected output after successful bootstrap:

7. Wait until the bootstrap procedure is complete.
   Either check the hcloud Loadbalancer is "up" for TCP/6443 on all nodes.
   Or use the `talosctl get machinestatus` command from before.

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

The `kubeconfig` is used by `kubectl` required for managing the K8S cluster.

```bash
talosctl kubeconfig -n "${CPIPS%%,*}"
```

## Deploying Cilium CNI

[Cilium](https://cilium.io/) is high-performance [CNI](https://www.cni.dev/) for Kubernetes using the eBPF algorithm.
We will deploy it using the Helm chart, loosely following the Talos [documentation](https://www.talos.dev/v1.3/kubernetes-guides/network/deploying-cilium/). Cilium is deployed with the `kube-proxy` replacement.

The cluster is already prepared for Cilium:

- Talos `kube-proxy` is disabled
- Talos CNI is set to none
- Kernel parameters are tuned out of the box

### Preparing the Deployment Manifest

Using `helm template`, the manifest that can be deployed to the cluster will be created.
The generated manifest is only valid for a specific cluster (certificates).

Feel free to use a newer version when applying (although newer versions might also have new issues to be resolved).

```bash
# Ensure that the LBIP variable is set
helm template cilium cilium/cilium --validate \
  --version 1.12.5 \
  --namespace kube-system \
  --set ipam.mode=kubernetes \
  --set kubeProxyReplacement=strict \
  --set k8sServiceHost="${LBIP}" \
  --set k8sServicePort="6443" \
  --set securityContext.privileged=true \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true > cilium.yaml
```

### Apply the Deployment Manifest

Deploy (install) the manifest using kubectl:

```bash
kubectl apply -f cilium.yaml
```

Wait a few minutes, then check the cilium status using kubectl or the clium CLI:

```bash
kubectl get pods -o wide -n kube-system
cilium status
```

## Troubleshooting Commands

## Talos

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

```
talosctl services 
```

## Kubernetes

| Component | Command                                                               | Description                               |
| :-------: | --------------------------------------------------------------------- | ----------------------------------------- |
|    K8S    | `kubectl get nodes -o wide`                                           | Lists the registered K8S nodes            |
|    K8S    | `kubectl get pods -o wide -A --field-selector spec.nodeName=worker-1` | Lists the pods running on specified node. |
kubectl describe pod kube-controller-manager-control-1 -n kube-system