# Preparations

In this session, we are initializing the hcloud project to be used for the workshop.
We are also going to deploy a jump server, which will be used to manage the K8S cluster.

## Initializing the hcloud Project

- Create a  new project in the hcloud console, for example: `k8s-playground-sewe`
- Create an API token for the project.
  It will be used by Terraform to manage hcloud resources.

## Bootstrapping Infrastructure with Terraform

- Configure a new Terraform Cloud project for the hcloud project
- Configure the mandatory variables.
- Start a new plan&apply run.

Confirm that the "apply" step worked and try to log in to the new jump server.
