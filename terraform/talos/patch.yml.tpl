machine:
  install:
    diskSelector:
      size: "<= 10GB"
  network:
    hostname: ${hostname}
    interfaces:
      - interface: eth0
        mtu: 9000
  # sysctls:
  #     net.ipv4.ip_forward: "0"
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
