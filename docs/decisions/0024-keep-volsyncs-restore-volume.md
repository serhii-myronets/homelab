---
id: "0024"
title: Keep VolSync's restore volume instead of cleaning it up
date: 2026-09-23
status: accepted
tags: [beelink, volsync, openebs, backup, storage, restore]
---

# Keep VolSync's restore volume instead of cleaning it up

Every claim built from `components/backed-up-volume` leaked two objects at
birth, and all eight services had done it. The `ReplicationDestination` runs
once, provisions a volume of its own, restores the R2 backup into it and
snapshots it; that snapshot is `status.latestImage`, the image the populator
fills the real claim from, so VolSync keeps it, and `trigger.manual` means no
later sync ever replaces it. `cleanupTempPVC: true` then deleted the volume
underneath the snapshot, and OpenEBS refuses to free a logical volume an LVM
snapshot still references. The result was a Released PV per service and
`csi-provisioner` retrying its deletion every two minutes for ever - over 200
attempts each between 05:31 and 17:56 on 2026-09-23.

The snapshot is not orphaned, which is why nothing collected it: VolSync sets
a controller reference to the `ReplicationDestination`, and Flux keeps that
object alive permanently. Its owner is immortal.

`cleanupTempPVC` is therefore dropped. The restore volume stays bound, the
snapshot references something that exists, and the failure cannot occur. It
costs one idle claim per service, holding a second copy of that service's data
from the moment it was restored. Measured across the eight data claims that
is 3.2 GiB against a 442 GiB thin pool, and only on a cluster that has
actually restored all of them - the existing eight will not re-run, because
their `restore-once` trigger is already satisfied.

A CronJob deleting snapshots whose source claim is gone was rejected: it
treats the symptom on a daily round, needs permission to delete snapshots in
every namespace, and adds a component to a cluster whose component count is
already the complaint. Removing the `ReplicationDestination` from Git after
the first restore was rejected too - Kubernetes would then collect the
snapshot with its owner, but the claim loses the self-restore that `0019` was
built for, and it reintroduces the manual step that already failed once: four
services were cleaned by hand on 2026-09-20 and four more had accumulated by
2026-09-23 with nobody noticing.

Kopiur, a Kopia-native operator whose design lists VolSync's leftover
snapshots among the gaps it exists to close, ties snapshot deletion to its own
resources and would fix this by construction rather than by omission. It is
`v1alpha1` with a CRD surface that is still moving, so it is worth revisiting
once it stabilises, not now.
