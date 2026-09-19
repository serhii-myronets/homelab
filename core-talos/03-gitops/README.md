# Argo-managed desired state

Apply `root.yaml` once to connect Argo CD to the child Applications. It creates
one child Application for each component, which Argo then reconciles from Git.

- `applications/system/` holds child Applications for cluster-wide components
  and their `system` AppProject.
- `applications/services/` holds child Applications for service workloads and
  their `services` AppProject.
- `components/system/` holds cluster-wide configuration such as network policy, secret
  stores, gateways and storage, grouped by purpose: `network/`, `storage/`,
  `database/`, `security/` and `platform/`. `applications/system/` mirrors the
  same groups, one Application per component.
- `components/services/` holds application workloads, one directory per service,
  each with its own namespace.

Every namespace Argo manages is a `namespace.yaml` in its component directory,
with its Pod Security label when it needs more than the default baseline; no
Application relies on `CreateNamespace`. A Helm-based component includes that
file through the repository source that also supplies its values.

`components/system/storage/openebs/` configures the `fast-local` OpenEBS LocalPV
Hostpath class for scratch data such as caches. Its backing XFS volume `cache`
is provisioned and mounted by Talos; OpenEBS only creates PVC directories
under `/var/mnt/cache/openebs`, whose generated names do not survive a
reinstall.

`components/system/storage/volumes/` defines static PVs, one file per consuming
service, pre-bound to that service's claims. Media use `local` PVs on the HDD
volumes `/var/mnt/hdd-a` and `/var/mnt/hdd-b`; configurations and databases
use `hostPath` PVs in a directory named after the service under
`/var/mnt/apps`, created on first use. Several PVs may point at the same disk,
and fixed paths let a reinstalled cluster find the same data. Argo neither prunes nor deletes them or the claims:
a released PV does not rebind to a recreated claim. A new consumer needs a file
here and matching claims in its own component.

A service is published on the internet by an HTTPRoute on `main-gateway` with
a name under `serhii.link`. external-dns then creates a proxied CNAME to the
Beelink tunnel, which `cloudflared` forwards to the Gateway, and Cloudflare
Access guards every such name. Other names on the Gateway get no public
record. external-dns owns only records it created (`txtOwnerId: beelink`), so
names still served by core's tunnel move by deleting them from that tunnel.

The Cilium, External Secrets and Argo CD releases remain in `../02-platform/`.
They establish GitOps; GitOps does not manage its own bootstrap layer yet.

The root Application creates both AppProjects before the Applications in
them. `system` may manage anything; `services` may create namespaces but no
other cluster-scoped object, so PVs and cluster configuration stay in system
components.
