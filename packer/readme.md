# Packer

This folder contains a packer script for generating the Talos OS hcloud snapshot image.
The image will be used by Terraform to deploy the Talos nodes.

## Creating the Talos Image

Obtain the hcloud API token of the project from Bitwarden or create a new token in the console.

```bash
export HCLOUD_TOKEN=<hcloud_API_token>

packer init .
packer build .
```
