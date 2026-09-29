---
id: "0030"
title: Back etcd up nightly with talosctl and restic, not talos-backup
date: 2026-09-29
status: accepted
tags: [beelink, talos, etcd, backup, restic, r2]
---

# Back etcd up nightly with talosctl and restic, not talos-backup

Wiping EPHEMERAL for swap (0029) showed how cheaply the cluster comes back
from an etcd snapshot, and how it would not come back at all without one:
VolSync keeps the volumes, not the objects that bind them. A CronJob in the
etcd-backup namespace now takes a snapshot every night through the Talos API
and keeps thirty days of them in R2.

Sidero's talos-backup was the obvious tool and was rejected on its
encryption. It encrypts only to age keys - it parses recipients with
`age.ParseRecipients`, which accepts native age keys and not the SSH key
already in use - so it would have added a private key that has to be kept
safe outside the cluster, beside the restic password that already has to be.
The job instead chains two official images: talosctl writes the snapshot and
restic stores it with the password and bucket of every VolSync repository.
Retention is restic's own `forget --keep-daily 30 --prune`, so no bucket
lifecycle rule is needed, and consecutive snapshots deduplicate.

Talos's API is opened narrowly: `kubernetesTalosAPIAccess` allows the one role
`os:etcd:backup` to the one namespace `etcd-backup`, and a talos.dev
ServiceAccount gives the job its credentials. The provider still generates
the v1.13 contract, so this uses `machine.features` rather than Talos 1.14's
KubeTalosAPIAccessConfig document.

A snapshot alone does not restore onto a new disk: Talos encrypts Secrets in
etcd with a key from `01-talos/secrets.yaml`. That file and the restic
password are the two things that must exist somewhere other than the Mac and
the cluster.
