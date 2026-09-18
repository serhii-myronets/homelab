# Bootstrap

Run from this directory. Requires `talosctl` matching the version in
`cluster.env`. This is a preparation workflow, not an automatic installer.

## Generate locally

```bash
./generate.sh
```

`cluster.env` pins versions, the initial API address and the Image Factory
schematic. `controlplane.patch.yaml` selects the installation disk by serial
and removes the control-plane scheduling taint for the single-node cluster.
The generator preserves the existing secrets bundle on subsequent runs.

`private/` is ignored by Git and restricted to the local user. It contains
`secrets.yaml`, `controlplane.yaml` and `talosconfig`; the later `kubeconfig`
also belongs there. Keep a separate secure copy of the secrets bundle:
Git cannot restore ignored files. Do not regenerate secrets for an existing cluster.

## Before installation

The bridge between physical LAN ports is still pending. After recabling,
read the node address from its console, inspect its links and addresses in
maintenance mode, and add the bridge configuration. Update `NODE_IP` and
regenerate if necessary. Arrange a stable address before bootstrap.

Review the generated configuration locally. Installation will write the
selected NVMe disk and reboot the host. Obtain the owner's approval before
applying; no HDD storage provisioning is included.

## Install and initialize once the network configuration is ready

```bash
source ./cluster.env
talosctl apply-config --insecure --nodes "$NODE_IP" --file private/controlplane.yaml
```

After the installed system starts, use its explicit client configuration
so commands cannot use another cluster's default context:

```bash
talosctl --talosconfig private/talosconfig version
talosctl --talosconfig private/talosconfig bootstrap
talosctl --talosconfig private/talosconfig health
talosctl --talosconfig private/talosconfig kubeconfig private/kubeconfig
kubectl --kubeconfig private/kubeconfig get nodes
```

Run `bootstrap` only once for the new cluster. The generated configuration
uses the default Flannel CNI. Application GitOps setup follows separately.
