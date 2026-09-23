---
id: "0025"
title: One namespace for the storage controllers, and why OpenEBS is not in it
date: 2026-09-23
status: accepted
tags: [beelink, kubernetes, storage, openebs, volsync, namespaces, helm]
---

# One namespace for the storage controllers, and why OpenEBS is not in it

The storage stack ran in three namespaces for no reason beyond each chart's
default: `snapshot-controller` in `kube-system`, VolSync in `volsync-system`,
OpenEBS in `openebs`. The first two are stateless cluster-wide controllers
that touch no disk and carry no system priority class, so they now share
`storage` - a name that matches the directory they are deployed from and keeps
the cluster's default baseline Pod Security level.

OpenEBS stays where it is, and this is not a preference. Its driver reads
`OPENEBS_NAMESPACE` from a fieldRef to its own pod, and keeps one `LVMVolume`
record per logical volume in that namespace - twenty of them here, each naming
a volume group, a capacity and an owning node. Moved, the driver would look
for those records beside itself, find none, and every mount, snapshot, resize
and delete against an existing volume would fail. Moving it means migrating
twenty custom resources on a live cluster, which buys nothing.

Putting all three in `openebs` instead was rejected for two reasons. The name
would then describe one of its three tenants, and `openebs` enforces the
privileged Pod Security level because the driver needs device access - which
would quietly remove the baseline guard the other two controllers have now.

The eight CRDs owned by the two charts all carry
`helm.sh/resource-policy: keep`, so they survived the uninstall with every
ReplicationSource, ReplicationDestination and VolumeSnapshot in them. They
also carry `meta.helm.sh/release-namespace`, which had to be repointed to
`storage` by hand before Flux installed: Helm refuses to adopt a resource
another release claims, and the install would have failed with `invalid
ownership metadata` after the old release was already gone. See traps.yaml.

The move is cosmetic and was done knowing it: nothing became faster, smaller
or more reliable, and one namespace fewer is the whole of the benefit.
