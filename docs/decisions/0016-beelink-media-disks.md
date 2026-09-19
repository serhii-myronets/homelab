---
id: "0016"
title: Keep the Beelink HDDs as two XFS volumes behind static local PVs
date: 2026-09-18
status: accepted
tags: [beelink, talos, kubernetes, storage, hdd, media]
---

# Keep the Beelink HDDs as two XFS volumes behind static local PVs

The two 10 TB HDDs hold replaceable media for a torrent client, Samba and
Jellyfin. The data must survive a reinstall of the cluster.

Talos provisions each disk as its own `UserVolumeConfig`, `hdd-a` and `hdd-b`,
mounted at `/var/mnt/hdd-a` and `/var/mnt/hdd-b`. Talos finds a user volume by
its partition label, so reinstalling with the same configuration reuses the
existing partitions instead of formatting them. A reset that wipes user disks
would still destroy them.

Kubernetes reaches them through static `local` PersistentVolumes with fixed
paths. Each consuming service has its own namespace and its own PVs, pre-bound
to its claims; several PVs point at the same disk. A shared namespace for all
media services was tried first and dropped: its Pod Security level had to be
relaxed for Samba's host network, which would have covered every other
service. OpenEBS Hostpath was rejected
for this data: it names each directory after a generated PVC UID, so a
reinstalled cluster would provision empty directories beside the old ones, and
separate claims would not share one library. The PVs select a Talos node label
rather than the hostname, because the generated hostname changes on reinstall.

XFS was chosen over ext4. Talos offers only these two, and ext4 would reserve
5% of each disk for root with no tuning option in the machine configuration.
Neither is readable on macOS or Windows without extra software; Samba makes
that irrelevant for clients.

The disks stay independent. A mirror would need ZFS as a Talos extension with
a manually created pool, and one spanning volume would lose both disks' data
when either fails. For replaceable media, losing one disk's contents is the
accepted risk.
