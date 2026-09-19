---
date: 2026-09-18
title: Simplify local files for the ME Pro bootstrap
tags: [talos, terraform, bootstrap, secrets]
---

The cluster had been installed and bootstrapped successfully. Talos v1.14.1
answered with RBAC enabled, and the Terraform state contained the machine
configuration, bootstrap and kubeconfig resources.

Removed the plan helper and generated plan, rendered machine config and local
copies of client configs. The active Talos and Kubernetes configs already live
in their standard user paths with the `me-pro` contexts.

Moved the local state, its backup and the original secrets bundle directly
under `core-talos/bootstrap/`. They remain plaintext and ignored by Git. The
explicit local backend was removed, restoring Terraform's default state path.

The owner chose Cilium with kube-proxy replacement for the next clean
bootstrap. Added the Talos 1.14 CNI patch, which deletes Flannel and disables
kube-proxy. Helm installation was explicitly deferred; no Cilium workload or
Talos configuration was applied during this preparation.

The owner later chose a small initial platform for the Beelink: Cilium,
External Secrets backed by Infisical, and Argo CD. Argo remains anonymously
accessible with administrator permissions on the LAN. Gateway API CRDs stay
because Cilium Gateway API is enabled; unused monitoring, Kafka, certificate
and VictoriaMetrics operators were removed from the initial bootstrap.

While validating the Helmfile, `helmfile build` ran its `prepare` hook. It
created the `external-secrets` namespace, applied Gateway API CRDs and applied
the local Infisical credential to the live Beelink cluster. It did not install
any Helm release. The behaviour is recorded in `docs/traps.yaml`.

Before the first Helm installation, Cilium was pinned to 1.20.2 and Argo CD to
chart 10.9.2. External Secrets remains at 2.10.0; its admission webhook and
certificate controller are disabled because CRD conversion is disabled. Its
single controller is limited to 100m CPU and 128Mi memory.

The generated Talos config retained its default installation path `/dev/sda`
alongside the NVMe selector. The node was verified to run its EPHEMERAL volume
from `/dev/nvme0n1p4`; the control-plane patch now explicitly selects
`/dev/nvme0n1` as well, protecting the two 10 TB HDDs during a later install.

The first Cilium agent crash loop reported that it could not determine a direct
routing device. Talos assigns the node IP to bridge `br0`, so Cilium values now
explicitly select that bridge with `devices: br0` and
`nodePort.directRoutingDevice: br0`.

The agent reads the generated configuration from an init container, so the
DaemonSet needed a rollout restart after the Helm upgrade. The replacement
Cilium pod became Ready and the Kubernetes node stayed Ready.

The Cilium chart defaults to two operator replicas. A single Beelink node can
run only one because both request the same host port, so the platform values
set `operator.replicas: 1`.

Prepared the first Argo-managed system directory without applying it. It owns
the Infisical `ClusterSecretStore`, the `gateway-system` namespace and a Cilium
Gateway. The Gateway's L2 policy announces through Talos bridge `br0`; its
pool is `192.168.8.15-192.168.8.20`, outside the router's DHCP range. The
old Proxmox-specific `10.1.1.x` pool, duplicate External Secrets values,
cert-manager, cloudflared and metrics-server files were removed. They need
their own installation and migration work before becoming desired state.

The first Argo sync created all system resources but left the Gateway pending.
Cilium 1.20.2 refused to start its Gateway controller because the bootstrap
had installed Gateway API v1.2.0. The platform source now pins v1.6.1, which
supplies the required TLSRoute, BackendTLSPolicy and v1 ReferenceGrant CRDs.

Added Metrics Server chart 3.14.0 as its own Argo Application. It runs in
`kube-system` and adds `--kubelet-insecure-tls` for Talos kubelet certificates.
Argo synced it successfully; the APIService became Available and `kubectl top`
returned metrics for the node and every pod.

The owner chose one Argo Application per component so the Argo UI exposes
independent status, history and synchronization. A root Application now reads
`03-gitops/applications/` recursively; its bootstrap manifest stays at the
GitOps root. Component Applications point straight to `03-gitops/components/`
or, for Helm charts, to their chart and local values. The former monolithic
`system` Application was deleted with orphan propagation only after the child
Applications were Healthy, so no component was removed during the migration.
Kustomization files were removed because none of these components needs patches
or overlays.

The owner added a 500 GB WD NVMe. It enumerates as `/dev/nvme0n1`, moving the
128 GB Talos system disk to `/dev/nvme1n1`; its serial selector is unchanged.
Updated the install patch's path for a future reinstall. The reboot logged DNS,
time-sync and Kubernetes API errors while `br0` had no default route; DHCP
finished, the route appeared and Talos health checks then passed.

The WD NVMe contained old data partitions, so Talos could not provision a user
volume until the owner explicitly approved wiping it. `talosctl wipe disk
nvme0n1 --method FAST` cleared only the verified WD disk with serial
`204390442013`. The Talos `UserVolumeConfig` now provisions its 499 GB XFS
partition as `u-fast`, mounted at `/var/mnt/fast` and bind-mounted into
kubelet. OpenEBS 4.6.0 uses only LocalPV Hostpath there through the
non-default `fast-local` StorageClass with `Retain`; Mayastor, LVM, ZFS,
Rawfile, Loki, Alloy and snapshot CRDs are disabled.

The two 10 TB HDDs carried empty-looking NTFS partitions from Windows; the
owner confirmed nothing on them mattered. `talosctl wipe disk sda sdb --method
FAST` cleared both after their WWIDs were rechecked. Talos then provisioned the
XFS user volumes `hdd-a` and `hdd-b`, selected by WWID because Talos reports no
serial for these disks. XFS reserves about 178 GB of each for metadata.

They are meant for a torrent client, Samba and Jellyfin, and must survive a
cluster reinstall, so they bypass OpenEBS: static `local` PVs point at the fixed
mount paths and bind to the claims `hdd-a` and `hdd-b` in `media`. The first
draft pinned the PVs to the hostname `talos-lqh-j5o`, which is generated and
would change on reinstall; Talos now labels the node `homelab/media-hdd=true`
and the PVs select that. The reasoning is `decisions/0016`.


The Beelink is a healthy single-node Talos cluster at `192.168.8.10`.
`fast-local` is ready for a first stateful workload, but no PVC has been
created yet. Keep Kubernetes stateful data on that class explicitly; it is
local to this node and therefore requires an application-level backup plan.
All Argo Applications, including `root`, `openebs` and `media-storage`, were
`Synced` and `Healthy` after commit `47ec0e1`. A test pod wrote to both HDD
claims. Their roots are `root:root 0755`, so the media applications must chown
them or run as root. Samba is the first service; torrent and Jellyfin are not installed yet, and
no data has been copied from core. The printer still writes to core's `scan`
share. Before relying on
a reinstall keeping the HDD data, confirm Talos reuses the `u-hdd-*`
partitions.
