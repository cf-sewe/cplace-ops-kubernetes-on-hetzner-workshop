#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

IMG_EXT="raw.xz"

# expect TALOS_VERSION and TALOS_BASE from environment
URL="https://github.com/siderolabs/talos/releases/download/${TALOS_VERSION}/hcloud-amd64.${IMG_EXT}"
gdisk -l /dev/sda

curl -fsSL -o talos-amd64.${IMG_EXT} "${URL}"
xz -dc talos-amd64.${IMG_EXT} | dd of=/dev/sda bs=4M

partprobe /dev/sda

sfdisk --delete /dev/sda 5
sfdisk --delete /dev/sda 6

gdisk -l /dev/sda
