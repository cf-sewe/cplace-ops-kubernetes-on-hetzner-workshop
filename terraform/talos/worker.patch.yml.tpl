machine:
  install:
    disk: "/dev/sdb"
  network:
    interfaces:
      - interface: eth0
        mtu: 9000
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
    dnsDomain: ${dnsdomain}