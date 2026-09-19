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

The owner wants the Beelink to replace core after a migration and chose to
start with Samba: guest access, LAN only, no backups yet, and the share names
core already uses. Samba runs in `media` from
`ghcr.io/servercontainers/samba`, with `torrents` on `hdd-a`, and `scan` and
the whole `hdd-b` on the second disk. Service workloads have their own Argo
project, which cannot create cluster-scoped objects.

The shares first answered inside the cluster but not from the LAN. Every
NodePort and LoadBalancer Service was affected; only the Gateway worked. A
`talosctl pcap` on br0 showed correct SYN-ACKs but data segments leaving from
the pod's port: iptables masqueraded them before Cilium restored the service
port. The owner applied `bpf.masquerade: true` through Helmfile and restarted
Cilium, after which the Mac listed the shares.

Guest writes then failed twice. Samba denied creating files in the 0755 share
roots owned by UID 1000, because it matched guests only through the group; the
roots became 0775. Directories created from Finder were then reset to 0755
through the fruit module's NFS ACEs; `fruit:nfs_aces = no` stopped it. A 2 GB
copy from the Mac wrote at about 52 MB/s and read at about 86 MB/s, before the
owner added a CPU limit.

The owner then wanted the server listed in Finder's Network like core. The
announcements are multicast and do not leave the pod network, so Samba moved to
the host network with the full image, running avahi and wsdd2, and the `media`
namespace now enforces the `privileged` Pod Security level. The
`192.168.8.16` LoadBalancer was removed; Samba answers on `192.168.8.10`.

At the owner's request the configuration moved from the image's environment
variables to files: `smb.conf` and the avahi configuration are generated into a
hashed ConfigMap, and the pod starts the image's runit services without its
entrypoint. Samba, avahi and wsdd2 are bound to `br0` only. The owner's Finder
mounted all three shares through Bonjour, and nested create, rename and delete
succeeded through those mounts.

The owner asked for the simplest possible access, so shares became
world-writable (0777 directories, 0666 files, still owned by UID 1000), and
the Samba container prepares the share roots itself instead of an init
container. The owner reported that whichever of a phone and the Mac connects
second waits 10 to 15 seconds before seeing files. With the Mac mounted, a
second client listed shares in 0.2 to 1.4 seconds, so the cause was not found.

The owner then asked how to avoid ownership conflicts between the media
services. Every media application will run as UID 1000, as on core, so Samba
went back to forcing that user with group-writable 0775/0664 modes. The
container only chowns the share roots at start: a recursive chown would walk
both disks on every restart. The files already written as `nobody` were
chowned once by hand. NetBIOS is on again for phone clients that browse with
it.

The owner disliked Samba living in a namespace called `media`, which existed
only because the HDD claims did. Several static PVs may point at one path, so
each consumer now gets its own: `hdd-volumes` defines `samba-hdd-a` and
`samba-hdd-b`, pre-bound to claims in the new `samba` namespace, which alone is
privileged. Samba owns its namespace, and each AppProject now lives in the
`applications/` directory it serves, replacing the project component. The
`torrents` directory and share were renamed `media` at the owner's request.
Argo Applications carry no finalizer, so removed Applications orphaned their
objects: the old `media` namespace and PVs were deleted by hand, and the
namespace and projects were adopted without being recreated. The Samba pod
kept running throughout the handover.

For a first test with real files, five movies (25.4 GB, including an H.265
file and a directory with subtitles) were copied from core's
`samba/torrents/Movies` to `hdd-a/media/Movies`. A temporary pod in `samba` ran
an rsync daemon on the host network, writing as UID 1000 and accepting only
core's address; core pushed with `rsync -rt` at 118 MB/s, and the pod was
deleted afterwards. Checksums matched. The daemon's umask left 0755/0644
despite `--chmod`, which rsync applies only with `-p`; the modes were fixed by
hand. For the full migration, set `incoming chmod = D775,F664` in the daemon.

On 2026-09-19 the WD NVMe, still empty, was split into the Talos volumes
`apps` (100 GB) and `cache` (399 GB); the reasoning is `decisions/0017`.
Applying the new configuration unmounted `fast` but could not provision the
new volumes until the owner wiped the disk, which auto mode refused to do.
`hdd-volumes` became `volumes`, one file of static PVs per service.

The torrent stack followed in the `torrent` namespace, privileged because
Gluetun needs NET_ADMIN. The owner stored the NordVPN credentials in Infisical
under `/nordvpn` by hand: a PushSecret from core's files was refused with 403,
because the cluster's machine identity may only read. Gluetun runs as a native
sidecar, so qBittorrent and Flood start only after the tunnel is healthy.
qBittorrent keeps core's image, settings and `/downloads` path, is bound to
`tun0`, and admits the LAN without a password. The pod resolves names through
Gluetun, and `FIREWALL_OUTBOUND_SUBNETS` lets replies reach the LAN and
kubelet.

qBittorrent's public IP was a NordVPN address in Amsterdam. Killing OpenVPN
blocked all traffic for about 17 seconds until it reconnected, and stopping
the Gluetun container blocked it for about 4 seconds while Kubernetes
restarted it; the home IP never appeared in either test.

Jellyfin came next, fresh rather than migrated. The Intel GPU device plugin
0.37.0 runs in `kube-system`, exempt from Pod Security, and shares the iGPU
with up to three pods, so Jellyfin in a baseline namespace gets it as
`gpu.intel.com/i915`; `vainfo` inside the pod reported the iHD driver with
H.264 encoding and HEVC 10-bit decoding. Jellyfin runs as UID 1000 with its
configuration on `apps`, transcodes on a 50 Gi `fast-local` claim, and reads
`hdd-a/media` as `/media`, the path core uses, so core's 12.0 library could
move later. That first `fast-local` claim stayed Pending: OpenEBS's
privileged helper pod was rejected by the baseline level in `openebs`, which
is now privileged. At the owner's request every Argo-managed namespace is now
a file in its component directory, OpenEBS included.

## Handoff

The Beelink is a healthy single-node Talos cluster at `192.168.8.10`. All Argo
Applications were `Synced` and `Healthy` after commit `bd2484f`. Samba serves
the `media`, `scan` and `hdd-b` shares to guests on the LAN as
`Beelink.local`. The torrent stack runs empty at `192.168.8.16`, and
Jellyfin runs at `192.168.8.17:8096` awaiting its first-run wizard, with
hardware transcoding still to be enabled in its settings.

Public access followed. Cloudflare routes a name to a tunnel by its DNS
record, not by the tunnel's ingress rules, so each cluster gets its own tunnel
and names move one record at a time. The owner created the locally managed
tunnel `beelink` with `cloudflared tunnel create`; `wildcard-tunnel`, whose
credentials were already in Infisical, stays for a future Proxmox cluster.
`cloudflared` sends every `serhii.link` name to the Gateway, and external-dns
publishes a proxied CNAME for each HTTPRoute under that domain. The first
secret paths pointed at `/cloudflare/beelink`; the owner's folder is
`/cloudflared/beelink`. external-dns first published the Gateway's LAN address,
because 0.22 ignores the `alpha` target annotation, which Cloudflare refused.
A dead-end test route proved that Cloudflare Access covers new names before
`flood.serhii.link` was published. The orphaned test TXT record was deleted
through the API. The owner declined to wait on external-dns: it is light, and
records now follow the routes in Git.

A full copy of core's `samba/torrents` (1.7 TB) to `hdd-a/media` started on
2026-09-19 at about 09:50 PDT, expected to take four and a half hours. It runs
on core as `nohup rsync ... rsync://192.168.8.10/media/`, logging to
`/tmp/beelink-rsync.log`, into the temporary pod `samba/rsync-receiver`, which
is not in Git, accepts only core's address and writes as UID 1000 with
`incoming chmod = D775,F664`.

Still to do, in one maintenance window once the copy has finished:

1. Stop qBittorrent and Jellyfin on core.
2. Rerun the same rsync for the changes since the first pass.
3. Copy core's Jellyfin configuration (`/srv/ssd/docker/data/jellyfin/config`,
   1.8 GB, version 12.0) into `/var/mnt/apps/jellyfin/`, replacing the fresh
   one, and qBittorrent's state (`BT_backup`, `categories.json` and the rest of
   `/srv/ssd/docker/data/torrent/qbittorrent/qBittorrent/` except its
   `qBittorrent.conf`, which Git owns) into `/var/mnt/apps/torrent/config/`,
   both owned by UID 1000. Both keep core's paths, `/media` and `/downloads`.
4. Start both on the Beelink; check that torrents resume without a full
   recheck and that Jellyfin shows the library and watch history. Review the
   transcoding settings for the N95.
5. Delete `samba/rsync-receiver`.

Do not configure the fresh Jellyfin on the Beelink before then: core's
configuration replaces it. A new service that needs the HDDs
gets its own PVs in `hdd-volumes`. Torrent and Jellyfin are not installed, no data has been copied from
core, and the printer still writes to core's `scan` share.

`fast-local` has no PVC yet; data on it is local to this node and needs an
application-level backup plan. Before relying on a reinstall keeping the HDD
data, confirm Talos reuses the `u-hdd-*` partitions.
