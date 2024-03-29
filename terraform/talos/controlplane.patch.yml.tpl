machine:
  install:
    disk: /dev/sda
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
  time:
    servers:
      - ntp1.hetzner.de
      - ntp2.hetzner.com
      - ntp3.hetzner.net
      - 0.de.pool.ntp.org
      - 1.de.pool.ntp.org

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
  # TODO: currently many deployments/docs are still not updated for Pod Security Admission
  #       for training we are enabling the unsecure "privileged" mode (for PROD unacceptable!)
  #       https://kubernetes.io/docs/concepts/security/pod-security-admission/
  apiServer:
    admissionControl:
      - name: PodSecurity
        configuration:
          defaults:
            enforce: privileged
