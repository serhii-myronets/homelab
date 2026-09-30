# Talos with Terraform

This directory manages satellite's Talos node, cluster bootstrap and client
configuration, the same way `../../core/01-talos/` does for core, with its own
secrets and its own state. Nothing here may reach core.

`main.tf` pins the Talos, Kubernetes and provider versions and the image
schematic, which is core's. `patches/` holds the install disk and control
plane limits, the static address and hostname, Cilium in place of the default
CNI and kube-proxy, the thin-pool module for LVM, and swap. The provider lock
file is committed.

`terraform.tfstate` and the generated `talosconfig` and `kubeconfig` are
plaintext local files ignored by Git. The state holds the cluster's secrets:
back it up outside the repository, and never delete it while the node lives.

## First install

1. Write the image to a USB stick and boot the machine from it with Secure
   Boot off:
   `https://factory.talos.dev/image/4b3cd373a192c8469e859b7a0cfbed3ecc3577c4a2d346a37b0aeff9cd17cdb0/v1.14.1/metal-amd64.iso`.
   It carries no configuration, so core's stick serves as well.
2. The node comes up in maintenance mode on a DHCP address; the router's
   client list shows it. Check what the patches assume before giving it
   anything:

   ```bash
   talosctl -n <address> get links --insecure   # enp1s0 must exist
   talosctl -n <address> get disks --insecure   # WWIDs ending GSMB2092400746, UB202412065113
   ```

3. Apply, pointing the first apply at the maintenance address. The node
   installs, reboots onto 192.168.8.20, and is bootstrapped there:

   ```bash
   terraform init
   terraform apply -var bootstrap_endpoint=<address>
   ```

4. Wipe the ORICO disk, which still carries the old machine's ext4 partition;
   the job in 03-gitops that makes it a volume group retries until the disk is
   empty and never erases it itself. This destroys its data - find its current
   name first, since `sda` and `sdb` swap between boots:

   ```bash
   talosctl -n 192.168.8.20 get disks
   talosctl -n 192.168.8.20 wipe disk <name> --drop-partition
   ```

5. Add the client configuration beside core's rather than over it:

   ```bash
   terraform output -raw talosconfig > talosconfig
   talosctl config merge talosconfig
   talosctl config context beelink   # merge makes satellite current; keep core's
   terraform output -raw kubeconfig > kubeconfig
   KUBECONFIG=~/.kube/config:kubeconfig kubectl config view --flatten > /tmp/kubeconfig.merged \
     && mv /tmp/kubeconfig.merged ~/.kube/config && chmod 600 ~/.kube/config
   ```

   Terraform names the Kubernetes context `admin@satellite`; rename it, since
   `02-platform/helmfile.yaml` is pinned to `satellite`:

   ```bash
   kubectl config rename-context admin@satellite satellite
   ```
   Until Cilium is installed from `02-platform/`, the node stays NotReady.

Upgrades follow Talos's own procedure, not a changed version string. Upgrade
satellite first and core after, so that satellite finds the problems.
