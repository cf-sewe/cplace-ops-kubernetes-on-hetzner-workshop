# Preparations

In this session, we are initializing the hcloud project to be used for the workshop.
We are also going to deploy a jump server, which will be used to manage the K8S cluster.

## Initializing the hcloud Project

- Create a  new project in the hcloud console, for example with the name `k8s-playground-sewe`
- Create an API token for the project.
  It will be used by Terraform to manage hcloud resources.

## Bootstrapping Infrastructure with Terraform

- Configure a new Terraform Cloud project for the hcloud project
- Configure the mandatory variables.
- Start a new plan&apply run.

Confirm that the "apply" step worked and try to log in to the new jump server.

## Checkout the GIT Repo on the Jump Server

The GIT repository contains files that are needed during the deployment.
Therefore, it needs to be checked out on the jump server.

(later) Initially, the deploy key used to check out the GIT repo needs to be specified (only once):

```bash
```

The repository can be cloned with the following command:

```bash
git clone git@github.com:cf-sewe/cplace-ops-kubernetes-on-hetzner-workshop.git
```
