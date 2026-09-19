# Talos with Terraform

This directory manages the bare-metal Talos node, cluster bootstrap and
kubeconfig retrieval. Run Terraform directly from here:

```bash
terraform init
terraform plan
terraform apply
```

`main.tf` pins the Talos, Kubernetes and provider versions. `patches/` holds
the installation, scheduling, network and storage configuration. The provider
lock file is committed.

`patches/storage.yaml` provisions 499 GB of the dedicated 500 GB WD NVMe by serial
number as two XFS user volumes, bind-mounted into kubelet: `apps` (100 GB) at
`/var/mnt/apps` for application configurations and databases, and `cache`
(399 GB) at `/var/mnt/cache` for the `fast-local` OpenEBS storage class. The
split keeps a growing cache from starving the applications.

`terraform.tfstate`, its backups and `secrets.yaml` are plaintext local files
ignored by Git. Back them up securely outside the repository. The state is the
authoritative record that the node was configured and bootstrapped; do not
delete it or import the secrets again over an existing state.

The Talos and Kubernetes client configurations live in their standard paths:

```text
~/.talos/config
~/.kube/config
```

Use `talosctl` and `kubectl` normally. The cluster name is `beelink`, so its
Talos context is `beelink` and its Kubernetes context is `admin@beelink`.

To replace the standard client configurations with the current cluster values,
run:

```bash
terraform output -raw talosconfig > ~/.talos/config
terraform output -raw kubeconfig > ~/.kube/config
chmod 600 ~/.talos/config ~/.kube/config
```

The stable Talos provider 0.11.0 uses the v1.13 configuration contract, while
the installed OS and validation CLI are Talos 1.14.1. Provider 0.12.0-rc.0 was
tested during setup but generated incompatible configuration documents.

It also provisions each 10 TB HDD, selected by WWID, as the XFS user volumes
`hdd-a` and `hdd-b` at `/var/mnt/hdd-a` and `/var/mnt/hdd-b`, and labels the
node `homelab/media-hdd=true` for the static PVs that use them. A reinstall
with this configuration reuses the existing partitions; never reset the node
with its user disks wiped. See `docs/decisions/0016`.

Talos and Kubernetes
upgrades also need their supported upgrade workflows; changing version strings
in generated machine configuration is not an upgrade procedure.
