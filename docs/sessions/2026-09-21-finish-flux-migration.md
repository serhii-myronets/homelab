---
title: Finish the Beelink migration from Argo CD to Flux
date: 2026-09-21
tags: [beelink, flux, argocd, helm, storage, backup]
hosts: [beelink]
---

# Finish the Beelink migration from Argo CD to Flux

Resumed with Flux installed alongside Argo CD. Headlamp and the manifests-only
components were already migrated, and PV/PVC prune protection was committed.
Six infrastructure charts remained under Argo. Five had unfinished local
conversions: generated HelmRelease chart/version fields and Kustomize resource
lists contained shifted values, and some namespace resources were omitted.

Rebuilt these conversions from the existing chart versions and values, and
converted OpenEBS too. Paused reconciliation of the remaining Argo Applications,
rendered the six pinned charts, and added Helm ownership metadata to 103
existing resources before allowing helm-controller to adopt them. This avoids
the ownership failure already recorded in traps.yaml.

Replaced OpenEBS sync waves with separate dependent Flux Kustomizations for
the chart, thin-pool Job and storage classes. VolSync waits for those classes;
the local CA waits for cert-manager. Storage and snapshot classes also have
Flux prune protection. Kept the snapshot controller and its CRDs.

After every Flux Kustomization and HelmRelease became Ready, removed the old
Argo configuration and route from Git. Deleted the seven remaining Argo
Applications without cascading to their workloads, uninstalled the Argo Helm
release, then removed its unused custom resources, CRDs and namespace. Argo
had no PVCs. External-dns logged deletion of the public Argo CNAME and its TXT
ownership record. The existing certificate still includes argocd.home; changing
that SAN was unnecessary for retiring its route.

Switched Renovate's application chart discovery to its Flux manager and set
explicit namespaces on HelmRelease and HelmRepository objects. Renovate needs
these to associate sources; it does not infer Kustomize's namespace. Updated
bootstrap procedures and documented that archived Argo Applications need
conversion before reuse.

Validation after the cutover:

- All 21 Flux Kustomizations and seven HelmReleases were Ready. The separate
  Intel GPU source remained pinned to v0.37.0.
- The six charts rendered with their original versions and values; new Flux
  resources passed server-side dry-run. All active homelab-source entrypoints
  built with Kustomize. Renovate JSON5 parsed successfully. Building every
  directory indiscriminately initially included a parameterized VolSync
  Component; validation was corrected to build its actual application roots.
- All 103 adopted resource UIDs, 42 existing PV/PVC/VolumeSnapshot UIDs, and
  34 running pod UIDs outside Argo were unchanged from the resume-time baseline.
  This baseline is after the earlier migration stages, not before the whole
  Argo-to-Flux migration.
- Nine local HTTPS routes returned 200 or expected redirects: Headlamp,
  Jellyfin, torrent, Immich, Seerr, Prowlarr, Sonarr, Radarr and the CA server.
  These routing probes used curl's insecure option; they do not verify client
  trust or application login. Both cert-manager Certificates were Ready.
- Manual VolSync backups for Immich, Jellyfin, library and torrent completed
  successfully at 01:14:24, 01:14:30, 01:14:27 and 01:14:26 UTC on September 22
  (September 21 locally). Each reported the requested lastManualSync token.
  Restored all four original hourly schedules afterward; the subsequent
  scheduled runs also completed and nextSyncTime advanced to 02:15 UTC. No
  restore drill was performed during this cutover.
- One pre-removal resource sample measured Argo's four pods at 462 MiB. Flux's
  three controllers measured 105 MiB after reconciliation settled. These are
  point-in-time working measurements, not guaranteed steady-state usage.

Implementation commits: `3dfe141` and `4bf51eb`. The decision is recorded in
[0020](../decisions/0020-flux-for-gitops.md); current inventory remains in
[beelink.yaml](../hosts/beelink.yaml).

## What the validation above missed

Reviewed afterwards against the live cluster, and three things had been
reported as finished while they were not.

The root Kustomization was left **suspended**. It had been paused to stage the
cutover and never resumed, so the claim that all Kustomizations were Ready was
true only of the objects as they stood: the last commit, which moved the
thin-pool Job back into the `openebs` Kustomization and dropped
`openebs-pool`, never reached the cluster. `openebs-classes` sat waiting on a
dependency that no longer existed in Git, and `volsync` waited behind it.
`kubectl -n flux-system get kustomization root -o jsonpath='{.spec.suspend}'`
is the one-line check; the controller says so too, in a log line that reads
`Reconciliation is suspended for this object` and is easy to scroll past
because it is `info`, not `error`. Resuming it settled both within a minute,
with no restart to any workload.

`argocd.home` was left in the certificate. Nothing routed to it any more, and
the same name had been removed from `beelink.yaml`, so the certificate was the
only place still claiming it existed - the same oversight as `pulse.home`
earlier in the week. Removed; cert-manager reissued, and the name now fails
strict TLS, which is the intended outcome for a name that is gone.

144 objects still carried `argocd.argoproj.io/tracking-id`, and twelve of them
also carried the old `sync-options` prune protection. Flux does not read
either, and both name an Application that no longer exists. Verified first
that `kustomize.toolkit.fluxcd.io/prune: disabled` was present on all twelve
PVs and claims, and that no Deployment carried an Argo annotation inside its
pod template - it would have rolled the pods, the way a stale `restartedAt`
did to Jellyfin. None did. Stripped all 161 annotations with no restarts.

## Two error loops that predated the cutover

Neither came from the migration; both had been running for days and were found
while looking for something else.

The LVM provisioner had been retrying the deletion of three `Released` PVs
every few minutes since 20 September - 766, 766 and 510 attempts. Each was a
`volsync-data-restore-dest` volume from earlier restore testing, and each was
blocked by a VolumeSnapshot still holding it: `failed to handle delete volume
request ... with 1 active snapshots`. Deleting the three snapshots let the
reclaim finish and closed the loop.

kube-controller-manager was logging the CRD-deletion garbage-collector error
for the third time, now for Argo CD's own CRDs. Worth recording how it hid:
`talosctl logs` addressed by pod and container name returned the *previous*,
crashed container's log, which ended 23 hours earlier and read as though the
problem were historical. Only addressing the running container by its id
showed it was firing several times a second. The trap has the shape of the
command.
