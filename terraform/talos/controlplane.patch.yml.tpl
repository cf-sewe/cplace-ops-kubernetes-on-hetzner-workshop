machine:
  certSANs:
    - ${loadbalancer_ipv4}
  install:
    disk: /dev/sda
  network:
    hostname: ${hostname}
    interfaces:
      - interface: eth0
        mtu: 9000
    nameservers:
      - 1.1.1.1

      - 2606:4700:4700::64
  # sysctls:
  #     net.ipv4.ip_forward: "0"
  # encrypt the EPHEMERAL and STATE partitions with a random key
  # systemDiskEncryption:
  #   ephemeral:
  #     provider: luks2
  #     keys:
  #       - nodeID: {}
  #         slot: 0
  #   state:
  #     provider: luks2
  #     keys:
  #       - nodeID: {}
  #         slot: 0
  time:
    servers:
      - ntp1.hetzner.de
      - ntp2.hetzner.com
      - ntp3.hetzner.net
      - 0.de.pool.ntp.org
      - 1.de.pool.ntp.org
    # forward logs to promtail
    # logging:
    #   destinations:
    #     - endpoint: tcp://1.2.3.4:12345
    #       format: json_lines

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
    #cni: none
    dnsDomain: ${dnsdomain}
# inlineManifests:
#   - name: cilium
#     contents: |
#       --
#       # Source: cilium/templates/cilium-agent/serviceaccount.yaml
#       apiVersion: v1
#       kind: ServiceAccount
#       metadata:
#         name: "cilium"
#         namespace: kube-system
#       ---
#       # Source: cilium/templates/cilium-operator/serviceaccount.yaml
#       apiVersion: v1
#       kind: ServiceAccount
#       -> Your cilium.yaml file will be pretty long....
