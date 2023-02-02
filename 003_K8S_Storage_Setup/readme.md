# Kubernetes Storage Setup

In this session, we will deploy Kubernetes storage.

- [Kubernetes Storage Setup](#kubernetes-storage-setup)
  - [Introduction](#introduction)
    - [Ephemeral vs. Persistent Storage](#ephemeral-vs-persistent-storage)
    - [CSI vs. CAS](#csi-vs-cas)
    - [Choice Persistent Volume CSI Driver](#choice-persistent-volume-csi-driver)
  - [Required Variables](#required-variables)
  - [Persistent Storage](#persistent-storage)
    - [OpenEBS LocalPV](#openebs-localpv)
    - [TopolVM Local Storage](#topolvm-local-storage)
    - [Setting up the Mayastor Storage](#setting-up-the-mayastor-storage)
    - [Setting up the DRBD/Piraeus Storage](#setting-up-the-drbdpiraeus-storage)

## Introduction

### Ephemeral vs. Persistent Storage

In Kubernetes, storage can be divided into two types: ephemeral storage and persistent storage.

Ephemeral storage refers to storage that is not saved across pod restarts or node failures.
It is also known as "transient storage".
When a pod is deleted or a node is shut down, any data stored in ephemeral storage is lost.
An example use case for ephemeral storage is caching, where data is not critical to persist.

On the other hand, Persistent storage refers to storage that is saved across pod restarts or node failures.
It is also known as "durable storage".
Persistent storage can be used for storing data that must be retained even if the pod or node is deleted.
This can include things like database data, user files, and so on.

When a pod is deployed in Kubernetes, it can be provisioned with both ephemeral and persistent storage.
The pod's containers can read and write data to these volumes, and the data will be available to the pod's containers even if the pod is deleted and recreated.
This makes it easy to store and manage data in a containerized environment.

In summary, Ephemeral storage is short-term temporary storage that is lost when a pod or node is deleted, while Persistent storage is long-term storage that is kept even if a pod or node is deleted, useful for maintaining data across restarts and node failures.

### CSI vs. CAS

CSI (Container Storage Interface) is a specification that defines how storage vendors can integrate with Kubernetes to provide different types of storage solutions to pods.
It provides a common set of APIs that storage vendors can implement, making it easier to use different storage solutions with Kubernetes.

CAS (Container Attached Storage) is a way to provide storage to pods by directly attaching a storage volume to a pod, rather than using a network file system like NFS.
It allows data to persist even after the pod is deleted and allows for better performance by reducing the network overhead.

### Choice Persistent Volume CSI Driver

cplace requires a persistent, highly available / replicated storage to store tenant data.
Throughput and latency (IOPS) are not much of a concern for cplace tenant data.
We will use *OpenEBS* for the training PoC.

Elasticsearch requires fast storage with high IOPS (low latency).
As an Elasticsearch cluster is performing replication itself, the K8S storage does not have to be replicated.
We will use *OpenEBS LocalPV hostpath* for the training PoC.

We will not use [Hetzner Cloud Volumes](https://github.com/hetznercloud/csi-driver).
While they seem to fulfill reliability requirements their performance is not great.
Also, the volumes do not work with dedicated servers.

[List of CSI drivers](https://kubernetes-csi.github.io/docs/drivers.html)

Many K8S CSIs require access to the full disk and do not work on a selected partition or filesystem.
For our use case, this is not ideal as we want to make efficient use of the 2x NVMe disks that are attached to the worker nodes.
Therefore we select CSIs that can work with a given directory.

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

## Persistent Storage

While all Kubernetes containers require ephemeral storage,
cplace requires a persistent highly available / replicated storage to store tenant data.
Throughput and latency (IOPS) are not much of a concern for cplace tenant data.

Elasticsearch requires a high IOPS (low latency) storage, that does not have to be replicated.

We will not use [Hetzner Cloud Volumes](https://github.com/hetznercloud/csi-driver).
While they seem to fulfill reliability requirements their performance is not great.
Also, the volumes do not work with dedicated servers.

[List of CSI drivers](https://kubernetes-csi.github.io/docs/drivers.html)

### OpenEBS LocalPV

OpenEBS LocalPV with HostPath uses storage locally attached to worker nodes.
The data is not replicated, so pods cannot be moved to other K8S nodes without data loss.

For the training PoC setup, we are using the Talos system disk as the LocalPV volume.
So no additional preparations are needed for the training setup.

For a production deployment that would be using dedicated servers with 1xSSD for the Talos OS, and 2x NVMe disks for data.
We could use one of the NVMe disks for the LocalPV, but this means that potentially a lot of space gets wasted.
The disk to be used for LocalPV needs to be prepared and initialized with a file system.
The initialization can be done by [Talos](https://www.talos.dev/v1.3/reference/configuration/#machineconfig) (XFS filesystem only) or by a pod that formats the disk (for example EXT4).

With the configuration below, LocalPV does *not* support quota / limiting the disk usage for a pod.

We are going to install OpenEBS by the provided Helm chart.
First, add the chart repository:

```bash
helm repo add openebs https://openebs.github.io/charts
helm repo update
```

Then install OpenEBS with the provided values:

```bash
helm install openebs openebs/openebs \
  --namespace openebs --create-namespace \
  --values "003_K8S_Storage_Setup/openebs/helm.values.yaml"
```

<details>
  <summary>Check that OpenEBS was installed properly, a good example would look like this:</summary>

  ```bash
  [ansible@jump openebs]$ kubectl get all -n openebs
  NAME                                               READY   STATUS    RESTARTS   AGE
  pod/openebs-localpv-provisioner-7495fdbb47-8k7jz   1/1     Running   0          29s

  NAME                                          READY   UP-TO-DATE   AVAILABLE   AGE
  deployment.apps/openebs-localpv-provisioner   1/1     1            1           29s

  NAME                                                     DESIRED   CURRENT   READY   AGE
  replicaset.apps/openebs-localpv-provisioner-7495fdbb47   1         1         1       30s
  ```
  </details>

For testing, a Busybox pod using a LocalPV PVC can be created:

```yaml
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: localpv-test
spec:
  storageClassName: openebs-hostpath
  accessModes:.
    - "ReadWriteOnce"
  resources:
    requests:
      storage: 5Gi
---
kind: Pod
apiVersion: v1
metadata:
  name: busybox
spec:
  securityContext:
    fsGroup: 2000
    runAsUser: 1000
    runAsNonRoot: true
  containers:
  - command:
       - sh
       - -c
       - 'date >> /mnt/data/date.txt; hostname >> /mnt/data/hostname.txt; sync; dd if=/dev/urandom of=/mnt/data/6GB bs=1M count=6000; sleep 5; sync; tail -f /dev/null;'
    image: busybox
    name: busybox
    volumeMounts:
    - mountPath: /mnt/data
      name: demo-vol
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL
      seccompProfile:
        type: RuntimeDefault
  volumes:
  - name: demo-vol
    persistentVolumeClaim:
      claimName: localpv-test
```

### TopolVM Local Storage

> if you look in to TopolVM, you’ll have to set an env var in the `topolvm-lvmd-0` daemonset when running on talos:

```yaml
lvmd:
  env:
    - name: LVM_SYSTEM_DIR
      value: /tmp
```

https://kubernetes.io/blog/2019/04/04/kubernetes-1.14-local-persistent-volumes-ga/
https://github.com/kubernetes-sigs/sig-storage-local-static-provisioner

OpenEBS:
  https://github.com/openebs/dynamic-localpv-provisioner
  https://github.com/openebs/lvm-localpv
  quota works with XFS and EXT4
  encryption not supported by operator

OpenEBS Local PV LVM ?

### Setting up the Mayastor Storage

Apply machine changes to the controlplane nodes:

```bash
talosctl patch --mode=no-reboot machineconfig \
  --patch '[{"op": "add", "path": "/machine/sysctls", "value": {"vm.nr_hugepages": "1024"}}, {"op": "add", "path": "/machine/kubelet/extraArgs", "value": {"node-labels": "openebs.io/engine=mayastor"}}]'
```

### Setting up the DRBD/Piraeus Storage

WORK IN PROGRESS

We will install Piraeus/LINSTOR/DRBD as K8S storage (CSI).
It has a [very high performance](https://blog.palark.com/kubernetes-storage-performance-linstor-ceph-mayastor-vitastor/), compared with other CSIs like OpenEBS.
We will just perform a very basic deployment (not production-ready).

Patch the Talos machine config and enable the drbd extension:

```bash
talosctl patch mc --patch-file drbd/install-drbd-extension.yaml --nodes "$WIPS"
```

Install the Piraeus operator:

```bash
git clone https://github.com/piraeusdatastore/piraeus-operator.git
cd piraeus-operator

# should be removed/replaced with more secure method
# e.g. dropping pod permissions and applying granular
kubectl label ns piraeus pod-security.kubernetes.io/enforce=privileged
kubectl label ns piraeus pod-security.kubernetes.io/auth=privileged
kubectl label ns piraeus pod-security.kubernetes.io/warn=privileged

helm install piraeus-op ./charts/piraeus \
  --namespace piraeus \
  --set operator.satelliteSet.kernelModuleInjectionMode=DepsOnly \
  --set etcd.enabled=false \
  --set operator.controller.dbConnectionURL=k8s

# Create device pool on worker-1/2
# TODO replace with operator provisioning
# https://github.com/piraeusdatastore/piraeus-operator/blob/master/doc/storage.md#preparing-physical-devices
kubectl linstor physical-storage create-device-pool \
  --pool-name nvme_lvm_pool LVM worker-1 /dev/sdb \
  --storage-pool nvme_pool
```

