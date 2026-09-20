---
date: 2026-09-19
title: Archive the database, add the library stack, split downloads from it
tags: [beelink, kubernetes, openebs, volsync, cloudnative-pg, arr, storage]
---

Three pieces of work on the Beelink, in order.

## One snapshot controller, not two

The owner checked the running pods and found that the OpenEBS controller pod
carries a `snapshot-controller` container of its own, v8.2.0, beside the
`csi-snapshotter` sidecar, while the standalone chart runs v8.6.0 in
kube-system. Our values switched off only the CRDs, which says nothing about
the controller, so two controllers were watching the same objects. The chart
documents the switch itself: `lvmController.snapshotController.enabled`, with
the comment that a cluster should have one. Rendering the chart with and
without it showed a difference of seven lines and one container, so it was
disabled. Both existing VolumeSnapshots stayed ReadyToUse and the hourly
VolSync runs at 03:15 UTC finished in 17 and 15 seconds.

Rolling that Deployment left its `CSIStorageCapacity` object owned by the old
ReplicaSet, which the new provisioner could never update; it logged the
conflict every second until the object was deleted and recreated.

## The database, kept whole and switched off

Nothing used Postgres: it held 7.8 MB and no table of its own, and it had
been built for Paperless, which the owner postponed. Rather than delete it,
CloudNativePG, the Barman Cloud plugin and the cluster moved unchanged into
`core-talos/03-gitops/archive/`, which the root Application does not read.
Git recorded the move as renames, so nothing inside was rewritten, and
`archive/README.md` gives the two commands that bring it back.

The namespaces, twelve CRDs, both webhooks and the RBAC were then removed.
The last step deadlocked: the `barman-cloud` Service held the finalizer
`cnpg.io/cleanupPlugin` and the operator that clears it was already gone, so
the finalizer was removed by hand. The backups stay in R2 under
`cnpg/postgres-v2` with a completed base backup, and the archived Cluster
bootstraps from them, so bringing the setup back restores the data with it.

## Downloads and library, told apart

One directory, `hdd-a/media`, served as both: qBittorrent seeded exactly the
files Jellyfin played. Anything that organised a release would have broken
its torrent, and deleting a torrent would have deleted the film. The owner
also pointed out that the `Kids` directory mixed 13 films with 5 series,
which no *arr can model - age is metadata, not a folder.

`media` was renamed to `torrents` and an empty `media` created beside it. A
rename inside one XFS filesystem is instant, so 1.7 TB did not move, and a
bind mount follows the inode rather than the name, so nothing noticed until
the pods rolled onto the new name. qBittorrent keeps `/downloads` over the
renamed directory, because its 56 torrents carry that path in their resume
data, and gains `/data`, the whole disk, which is what Sonarr and Radarr also
mount: identical paths everywhere, so no download client path mapping.
Jellyfin keeps its migrated library through `/media`, now over `torrents`,
and gains `/library` for what the two managers build - so nothing stopped
playing. Samba gained a `torrents` share beside `media`.

Prowlarr, Sonarr and Radarr went into a namespace called `library`, the name
the owner chose over `arr`: torrent fetches, library organises, jellyfin
plays. They were written as three Deployments sharing one configuration
claim, which failed: the OpenEBS LVM driver refuses to mount a logical volume
into a second pod even on one node, so Prowlarr took it and the other two
never started. They now share one pod, as qBittorrent and Flood do.

The first claim also arrived broken, bound to a PV with no logical volume
behind it. The CSI log named the cause: csi-provisioner's leak protection
deleted the volume one second after creating it, because VolSync's populator
had removed the temporary `vs-prime-` claim it was provisioned for. It is a
race; deleting the claim and letting it be made again was enough. All three
traps are in `docs/traps.yaml`.

## Local names reach their certificate

The owner asked why the services had no certificates. They have one - TLS
ends at the Gateway, and the routes only claim a name - but the HTTP
listener carried no hostname, so it answered local names too and a name
typed without a scheme never reached HTTPS. A blanket redirect was not
available: cloudflared speaks plain HTTP to the same port, and redirecting
it would have looped every public name.

The listeners are now told apart by hostname. `*.serhii.link` on port 80 is
the tunnel's. `*.home` on port 80 admits routes from gateway-system alone
and holds one redirect to HTTPS - alone, because an exact hostname beats a
wildcard and any service route sharing that listener would take its own
name back. `ca.home` keeps a plain listener, since a device fetching the
root certificate does not trust it yet.

## Handoff

`prowlarr.home`, `sonarr.home` and `radarr.home` answer 200 over HTTPS and
are in the certificate. The programs are running and unconfigured. What is
left is in their own interfaces: indexers in Prowlarr and the two
applications to push them to, qBittorrent as the download client at
`torrent.torrent.svc.cluster.local:8080`, which needs no password from the
pod network, root folders `/data/media/movies` and `/data/media/tv`, and then
importing what is already on the disk out of `/data/torrents`.

That import is the one dangerous step. Media Management must have "Use
Hardlinks instead of Copy" on before anything is imported, or the files will
be moved out from under the torrents seeding them. `Kids` needs no sorting:
each item is identified on its own and lands in films or series. Releases
named in Ukrainian or Russian will need identifying by hand.

All 56 torrents are complete and stopped, with no missing files - they were
already stopped before the rename. Jellyfin's `/media` mount and
qBittorrent's `/downloads` mount both exist only until the import is done.
