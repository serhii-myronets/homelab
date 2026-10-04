# Talos with Terraform

This directory manages the bare-metal Talos node, cluster bootstrap and
kubeconfig retrieval. Run Terraform directly from here:

```bash
terraform init
terraform plan
terraform apply
```

`main.tf` pins the Talos, Kubernetes and provider versions and renders two
nodes: the Beelink as `controlplane` and the old OpenMediaVault box as
`worker-1`.
`patches/common/` applies to both, `patches/controlplane/` to the Beelink and
`patches/worker/` to worker-1 - each machine's install disk, network,
storage and swap. The provider lock file is committed.

worker-1's first configuration goes to its maintenance address, passed once
as `-var worker_1_bootstrap_endpoint=<address>`; every later apply reaches it
at 192.168.8.11. It carries the taint `homelab/dedicated=worker-1:NoSchedule`,
set by the kubelet when it registers, so only what tolerates it runs there.
The kubelet sets it only at registration: on a registered node, change it
with `kubectl taint` as well.

`patches/controlplane/storage.yaml` leaves the 500 GB WD NVMe unclaimed: it is one LVM
volume group for OpenEBS LVM LocalPV, created by a Job in `03-gitops` because
this provider's configuration contract has no LVMVolumeGroupConfig. See
`docs/decisions/0019`.

The state lives in R2, bucket `homelab-backups`, key
`terraform/core-01-talos.tfstate`, through the s3 backend in `main.tf`. It
reads its credentials from an `r2` profile in `~/.aws/credentials`; on a new
Mac, make it from Infisical's `/system/backups` before `terraform init`:

```ini
[r2]
aws_access_key_id = <R2_ACCESS_KEY_ID>
aws_secret_access_key = <R2_SECRET_ACCESS_KEY>
```

The cluster is made from its Talos secrets in Infisical,
`/system/talos/SECRETS_YAML` in `secrets.yaml`'s format: Terraform reads them
on every run (`docs/decisions/0041`). `secrets.yaml` stays here as a local,
ignored copy. Both are readable by the cluster itself - accepted in
`docs/decisions/0037`.

Terraform logs in to Infisical as the owner, with the CLI's own session. The
provider cannot read it from the Keychain, where the CLI keeps it, so a
function in `~/.zshrc` hands it to every run:

```zsh
terraform() { INFISICAL_AUTH_METHOD=token INFISICAL_TOKEN=$(infisical user get token --plain 2>/dev/null) command terraform "$@"; }
```

From the secrets, on every run and never kept in the state, Terraform makes
the admin's talosconfig and kubeconfig, valid as long as their CAs. An apply
writes them to Infisical as `/system/talos/TALOSCONFIG` and `KUBECONFIG`, and
`scripts/contexts.sh` merges them into `~/.talos/config` and `~/.kube/config`
as the contexts `core` and `admin@core`, replacing core's and leaving the
lab's, and which context is current, alone. On another Mac, after
`infisical login`:

```bash
terraform plan -replace=terraform_data.contexts -out=contexts.plan
terraform apply contexts.plan
```

The stable Talos provider 0.11.0 uses the v1.13 configuration contract, while
the installed OS and validation CLI are Talos 1.14.1. Provider 0.12.0-rc.0 was
tested during setup but generated incompatible configuration documents.

The same patch provisions each 10 TB HDD, selected by WWID, as the XFS user volumes
`hdd-a` and `hdd-b` at `/var/mnt/hdd-a` and `/var/mnt/hdd-b`, and labels the
node `homelab/media-hdd=true` for the static PVs that use them. A reinstall
with this configuration reuses the existing partitions; never reset the node
with its user disks wiped. See `docs/decisions/0016`.

Talos and Kubernetes
upgrades also need their supported upgrade workflows; changing version strings
in generated machine configuration is not an upgrade procedure.
