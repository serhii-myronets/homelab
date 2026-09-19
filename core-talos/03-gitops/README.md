# Argo-managed desired state

Apply `root.yaml` once to connect Argo CD to the child Applications. It creates
one child Application for each component, which Argo then reconciles from Git.

- `applications/system/` holds child Applications for cluster-wide components.
- `applications/services/` holds child Applications for service workloads.
- `components/system/` holds cluster-wide configuration such as network policy, secret
  stores, gateways and storage.
- `components/services/` holds application workloads, one directory per service.

`components/system/openebs/` configures the `fast-local` OpenEBS LocalPV
Hostpath class. Its backing XFS volume is provisioned and mounted by Talos;
OpenEBS only creates PVC directories under `/var/mnt/fast/openebs`.

`components/system/media-storage/` binds the HDD volumes to the `media`
namespace as the claims `hdd-a` and `hdd-b`, through static PVs with fixed
paths. Argo neither prunes nor deletes them: a released PV does not rebind to a
recreated claim.

The Cilium, External Secrets and Argo CD releases remain in `../02-platform/`.
They establish GitOps; GitOps does not manage its own bootstrap layer yet.

The `system` project is created first. Its component Applications use it for
cluster-wide configuration and charts; service Applications follow the same
pattern under `applications/services/`.
