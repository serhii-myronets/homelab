# Argo-managed desired state

Apply `root.yaml` once to connect Argo CD to the child Applications. It creates
one child Application for each component, which Argo then reconciles from Git.

- `applications/system/` holds child Applications for cluster-wide components
  and their `system` AppProject.
- `applications/services/` holds child Applications for service workloads and
  their `services` AppProject.
- `components/system/` holds cluster-wide configuration such as network policy, secret
  stores, gateways and storage.
- `components/services/` holds application workloads, one directory per service,
  each with its own namespace.

`components/system/openebs/` configures the `fast-local` OpenEBS LocalPV
Hostpath class. Its backing XFS volume is provisioned and mounted by Talos;
OpenEBS only creates PVC directories under `/var/mnt/fast/openebs`.

`components/system/hdd-volumes/` defines static PVs on the Talos HDD volumes,
one set per consuming service, pre-bound to that service's claims. Several PVs
may point at the same disk. Argo neither prunes nor deletes them or the claims:
a released PV does not rebind to a recreated claim. A new consumer needs a file
here and matching claims in its own component.

The Cilium, External Secrets and Argo CD releases remain in `../02-platform/`.
They establish GitOps; GitOps does not manage its own bootstrap layer yet.

The root Application creates both AppProjects before the Applications in
them. `system` may manage anything; `services` may create namespaces but no
other cluster-scoped object, so PVs and cluster configuration stay in system
components.
