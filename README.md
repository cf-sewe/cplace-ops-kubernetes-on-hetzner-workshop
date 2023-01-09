# Workshop: cplace on Kubernetes on Hetzner Cloud

We are conducting a workshop setting up cplace on a Kubernetes cluster running in the Hetzner Cloud.

The goals are:

1. Building up Kubernetes cluster architecture and operation know-how within the cplace Operations Team.
2. Building a PoC for running Kubernetes on the Hetzner Cloud, serving as a foundation for our road-map initiatives for 2023.
3. Running cplace on Kubernetes without the abstractions of the cplace Operator.

That allows us to understand the required Kubernetes components better
and allows to build up know-how on how to support cplace in a Kubernetes environment.

## Workshop Contents

### Basic Kubernetes Deployment

We will deploy Kubernetes on Hetzner using the following technologies:

- [Hetzner Cloud](https://www.hetzner.com/cloud)
  - Virtual Machines
  - Loadbalancer
  - Storage
- [Talos OS](https://www.talos.dev/latest/introduction/what-is-talos/)
- [Cilium](https://docs.cilium.io/en/stable/intro/) (CNI)
- [Piraeus](https://piraeus.io/site/docs/intro/)/[Linstor/DRBD](https://linbit.com/linstor/) (CSI)
- [Traefik](https://doc.traefik.io/traefik/) (Ingress/Gateway)

### MySQL

A MySQL cluster deployed to Kubernetes will be used as the cplace RDB.
We have selected the [Percona Operator for MySQL based on Percona XtraDB Cluster](https://docs.percona.com/percona-operator-for-mysql/pxc/scaling.html),
as it provides a great out-of-the-box experience, reducing operational efforts significantly.

[Vitess](https://vitess.io/)?

### Elasticsearch

An Elasticsearch cluster deployed to Kubernetes will be used as the cplace NoSQL database.
We have selected the [Elasticsearch operator](https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-overview.html) to simplify the deployment and operation of the ES cluster in K8S.

### cplace Deployment from Kubernetes Manifests

xxx

#### Kustomize

xxx

#### Deployment

xxx

## Required Production Changes

The workshop intentionally applies some simplifications, to ensure the team can duplicate the results quickly.

- Grafana/Prometheus/Loki stack
- Kubernetes logging to Loki
- Talos kernel logging to Loki

## Glossary

RDB Relational Database
CNI Container Network Interface
CSI Container Storage Interface
CAS Container Attached Storage
K8S Kubernetes (K with 8 more letters and an S)
hcloud Hetzner Cloud
kubectl The kubernetes CLI tool


## Useful Links

- Storage performance benchmarks: https://blog.palark.com/kubernetes-storage-performance-linstor-ceph-mayastor-vitastor/
- 