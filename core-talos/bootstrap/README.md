# Bootstrap with Terraform

This directory manages the bare-metal Talos node, cluster bootstrap and
kubeconfig retrieval. Run Terraform directly from here:

```bash
terraform init
terraform plan
terraform apply
```

`main.tf` pins the Talos, Kubernetes and provider versions. `patches/` holds
the installation, scheduling and network configuration. The provider lock
file is committed.

`terraform.tfstate`, its backups and `secrets.yaml` are plaintext local files
ignored by Git. Back them up securely outside the repository. The state is the
authoritative record that the node was configured and bootstrapped; do not
delete it or import the secrets again over an existing state.

The Talos and Kubernetes client configurations live in their standard paths:

```text
~/.talos/config
~/.kube/config
```

Use `talosctl` and `kubectl` normally. The current contexts are `me-pro` and
`admin@me-pro`.

The stable Talos provider 0.11.0 uses the v1.13 configuration contract, while
the installed OS and validation CLI are Talos 1.14.1. Provider 0.12.0-rc.0 was
tested during setup but generated incompatible configuration documents.

The two HDDs are not provisioned by this bootstrap. Talos and Kubernetes
upgrades also need their supported upgrade workflows; changing version strings
in generated machine configuration is not an upgrade procedure.
