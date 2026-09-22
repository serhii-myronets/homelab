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
