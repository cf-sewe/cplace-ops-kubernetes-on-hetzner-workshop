machine:
  install:
    disk: "/dev/sda"
    extensions:
      - image: ghcr.io/siderolabs/drbd:9.2.0-v1.3.0
  network:
    nameservers:
      - 1.1.1.1
      - 1.0.0.1
  # encrypt the EPHEMERAL and STATE partitions with a random key
  systemDiskEncryption:
    ephemeral:
      provider: luks2
      keys:
        - nodeID: {}
          slot: 0
    state:
      provider: luks2
      keys:
        - nodeID: {}
          slot: 0
  kubelet:
    #extraArgs:
    #  node-labels: "openebs.io/engine=mayastor"
    # ensure openebs directory from host is mounted into kubelet
    extraMounts:
      - destination: /var/openebs/local
        type: bind
        source: /var/openebs/local
        options:
          - bind
          - rshared
          - rw
  kernel:
    modules:
      - name: drbd
      - name: drbd_transport_tcp

# Traefik
# https://github.com/lucas-clemente/quic-go/wiki/UDP-Receive-Buffer-Size
# https://www.talos.dev/v1.3/kubernetes-guides/configuration/storage/#prep-nodes
sysctls:
  net.core.rmem_max: "2500000"
  vm.nr_hugepages": "1024"

cluster:
  discovery:
    enabled: true
    registries:
      kubernetes:
        disabled: false
      # deactivate call-home function
      service:
        disabled: true
  network:
    cni:
      name: none
    dnsDomain: ${dnsdomain}
  proxy:
    disabled: true
