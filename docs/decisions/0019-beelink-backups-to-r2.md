---
id: "0019"
title: Back the Beelink up to R2, and let its volumes restore themselves
date: 2026-09-19
status: accepted
tags: [beelink, backup, volsync, cloudnative-pg, lvm, openebs, r2]
---

# Back the Beelink up to R2, and let its volumes restore themselves

Cloudflare R2 holds the backups: its free tier covers this data, egress is
free, and it is the first copy of anything here that lives outside the house.
Credentials are in Infisical under `/backups/R2`; the restic password also
belongs in a password manager, because without it the backups are unreadable.

Postgres backs itself up through CloudNativePG's Barman Cloud plugin:
continuous WAL archiving plus a daily base backup. That half is switched off
as of 2026-09-19, waiting for an application that needs a database; the
manifests are kept whole in `core-talos/03-gitops/archive/database/` and its
backups stay in R2.

Everything else is a PersistentVolumeClaim backed up hourly by VolSync with
restic, from a snapshot rather than from live files, so a SQLite database is
never copied mid-write. A service's claim declares where it restores from, so
an empty cluster fills it from R2 before the service starts; with no backup
yet it starts empty.

This needs snapshots, which OpenEBS Hostpath cannot take, so the WD NVMe is
now a single LVM volume group with a thin pool, and OpenEBS LVM LocalPV gives
each claim a thin logical volume. Thin, because only thin snapshots can be
restored into a new volume. The volume group replaces the `apps` and `cache`
split of `0017`: a logical volume has a hard size of its own, so nothing has
to be walled off by partition any more. The group and the pool are created by
a job in the cluster rather than by Talos, whose Terraform provider still
speaks the v1.13 configuration contract.

Media on the HDDs stay out: 20 TB in object storage costs more than
downloading them again. Caches are separate claims with no backup at all.

Longhorn was the alternative: one component instead of four, with snapshots,
scheduled backups and a UI. It was rejected because its restore is not
automatic, it needs Talos system extensions and an iSCSI data path, it costs
around a gigabyte of memory, and its replication - the reason it exists -
does nothing on a single node.
