# Bootstrap with Terraform

Run commands from this directory. Requires Terraform >= 1.5, Python 3 and
Talos CLI 1.14.1. `main.tf` owns versions, API address and installer image;
YAML patches own the installation disk, scheduling and network bridge.

The stable Talos provider 0.11.0 uses the v1.13 configuration contract.
The installer is pinned separately to Talos 1.14.1. The generated configuration
is validated with the 1.14.1 CLI. Provider 0.12.0-rc.0 was tested but produced
incompatible configuration documents; do not upgrade the provider casually.

## Local state and secrets

`private/` is ignored by Git and contains plaintext secrets, state, state
backups, saved plans and generated credentials. Back up this directory
securely outside this machine. The provider lock file is committed.

The existing `private/secrets.yaml` has already been imported locally. On a
fresh checkout, restore the private directory and run `terraform init`.
If restoring only the original secrets bundle before the first deployment:

```bash
umask 077
mkdir -p private
chmod 700 private
terraform init
terraform import talos_machine_secrets.cluster private/secrets.yaml
```

Do not re-import over existing state or generate new secrets for an existing
cluster. If the cluster has already been deployed, restore its state as well;
importing secrets alone does not record the machine or completed bootstrap.

## Review the plan

```bash
./plan.sh
```

This writes the plan, rendered `controlplane.yaml` and `talosconfig` to
`private/` and validates the rendered config. It does not change the node.
The initial plan should have three creates and no changes to cluster secrets.

Before applying, reserve the configured node address in the router UI for
the bridge MAC in `network.patch.yaml`. The bridge uses DHCP and preserves
the uplink MAC; a DHCP lease alone does not guarantee a permanent address.
Keep Mac Wi-Fi available while the bridge is brought up. Physical wiring:
router to enp3s0, monitor Ethernet to enp2s0, monitor Thunderbolt to Mac.
Disconnect the old USB network connection between ME Pro and the monitor.

## Install and bootstrap

Obtain owner approval first: applying writes the selected NVMe and may reboot
the node. It also changes networking and initializes the cluster. The HDDs
have no provisioning configuration. Inspect `private/controlplane.yaml`
locally before proceeding.

```bash
umask 077
terraform apply private/bootstrap.tfplan
terraform output -raw talosconfig > private/talosconfig
terraform output -raw kubeconfig > private/kubeconfig
talosctl --talosconfig private/talosconfig health
kubectl --kubeconfig private/kubeconfig get nodes
```

Terraform orders configuration application, one-time bootstrap, then kubeconfig
retrieval. Keep its state to preserve that history. The default CNI is Flannel.
The node is allowed to run application workloads. Applications are managed
separately from this bootstrap directory.

## Later changes

Edit the source, run `./plan.sh`, inspect the patch and apply the reviewed plan.
Configuration changes can interrupt networking or require a reboot.
`prevent_destroy` protects secrets, the machine configuration and bootstrap;
node reset on destroy is disabled explicitly.

Changing the installer image or Kubernetes version in generated configuration
is not an upgrade procedure for a running cluster. Plan Talos and Kubernetes
upgrades separately using their supported upgrade workflows.
