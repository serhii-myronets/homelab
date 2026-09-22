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
described here. The root reads `apps/` and creates one Flux Kustomization per
component; each reconciles its directory under `components/`.

- `apps/system/` and `components/system/` hold cluster-wide infrastructure,
  grouped by network, security, storage and platform.
- `apps/services/` and `components/services/` hold service workloads.
- Helm components define a pinned `HelmRepository` and `HelmRelease` beside
  their namespace and other manifests. Chart values are inside the
  HelmRelease, with drift detection enabled.
- `archive/` is outside the reconciled tree. Its older Argo Applications need
  conversion before they can be restored; see its README.

A component owns its namespace where needed. Dependencies are explicit in
Flux `spec.dependsOn`; Argo sync-wave annotations do not order Flux applies.
The `openebs` Kustomization installs the chart and runs the thin-pool Job
together, waiting for both. `openebs-classes` publishes the storage classes
only after they are ready.
The standalone snapshot controller owns the snapshot CRDs. VolSync waits for
the storage classes, and the local CA waits for cert-manager.

OpenEBS LVM LocalPV provisions thin volumes on the NVMe group. The one-time
pool job is idempotent. Configuration claims use VolSync's R2 restore source;
caches are excluded from backups. `components/system/storage/volumes/`
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
