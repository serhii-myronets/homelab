# Flux-managed desired state

Bootstrap Cilium, External Secrets and the Flux Operator from
`../02-platform/` with Helmfile, then apply two manifests once, in this order,
from the repository root:

```sh
kubectl apply -f core-talos/02-platform/flux-instance.yaml
kubectl apply -f core-talos/03-gitops/flux.yaml
```

The first tells the operator which Flux controllers to install and how to size
them; the operator upgrades them within its pinned minor range on its own. The
second defines the `homelab` GitRepository and the root Flux Kustomization -
deliberately not the operator's `spec.sync`, so the desired state stays
described here.

The root reconciles `apps/`, whose `kustomization.yaml` names every `ks.yaml`
in the tree and nothing else. Each `ks.yaml` is a Flux Kustomization pointing
at the `app/` directory beside it:

```
apps/services/jellyfin/ks.yaml     the Kustomization
apps/services/jellyfin/app/        what it reconciles
```

That index matters: without it the root would scan the tree and apply the
manifests inside every `app/` itself, bypassing the Kustomizations that own
them. Adding a component means adding a directory and one line there.

- `apps/system/` holds cluster-wide infrastructure, grouped by network,
  security, storage and platform; `apps/services/` holds service workloads.
  The split is what orders reconciliation.
- `components/` is for kustomize Components only - fragments merged into
  several apps rather than deployed on their own. One so far:
  `backed-up-volume`, which gives a service a `data` claim that is backed up
  hourly to R2 and restores itself on an empty cluster. It is named for what
  it provides, not for VolSync which implements it, because the VolSync
  controller is a separate component under `apps/system/storage/`.
- Three components are a single file with no directory: two are HelmReleases
  with no manifests beside them, the third carries its own upstream source.
- A Helm component is a pinned `HelmRelease` beside its namespace and other
  manifests, with the chart values inside it and drift detection enabled. The
  chart's source is not beside it: every `HelmRepository` is listed in
  `apps/helm-repositories.yaml`, and a chart cannot come from a repository
  absent from that file.
- Setups that worked and were switched off live in `../../archive/` at the
  repository root, not here: this directory is what Flux reconciles, and they
  are not. Their older Argo Applications need conversion before they can be
  restored; see that README.

A component owns its namespace where needed. Dependencies are explicit in
Flux `spec.dependsOn`; Argo sync-wave annotations do not order Flux applies.
The `openebs` Kustomization installs the chart and runs the thin-pool Job
together, waiting for both. `openebs-classes` publishes the storage classes
only after they are ready.
The standalone snapshot controller owns the snapshot CRDs, and openebs waits
for it through `HelmRelease.spec.dependsOn` rather than through a
Kustomization - the dependency sits on the chart that actually needs the CRDs,
which is why that controller needs no directory. VolSync waits for the storage
classes, and the local CA waits for cert-manager.

OpenEBS LVM LocalPV provisions thin volumes on the NVMe group. The one-time
pool job is idempotent. Configuration claims use VolSync's R2 restore source;
caches are excluded from backups. `apps/system/storage/volumes/app/`
defines static HDD PVs pre-bound to each service's claims. Their Flux prune
protection, and the matching protection on the claims, prevents Git removal
from deleting them. This is separate from a StorageClass's reclaim policy;
do not delete claims as a way to restart services.

A public HTTPRoute under `serhii.link` is published by external-dns as a proxied
CNAME to the Beelink tunnel. cloudflared forwards to the Gateway, and Cloudflare
Access guards those names. Routes under `.home` remain local.

The operator serves a read-only web view of all of this on `flux.home`, and
on `flux.serhii.link` behind Cloudflare Access - see
[decisions/0021](../../docs/decisions/0021-flux-operator-for-the-web-interface.md).

Check reconciliation without installing a separate Flux CLI:

```sh
kubectl -n flux-system get fluxinstance,gitrepositories,kustomizations
kubectl get helmreleases -A
kubectl get replicationsources -A
```

To fetch a pushed commit immediately:

```sh
kubectl -n flux-system annotate gitrepository homelab \
  reconcile.fluxcd.io/requestedAt="$(date -u +%Y-%m-%dT%H:%M:%SZ)" --overwrite
```

Cilium, External Secrets and Flux itself remain Helmfile-managed in
`../02-platform/`. Renovate proposes updates; merging a Helmfile update does
not apply it. Merging updates under the Flux-managed tree does.
