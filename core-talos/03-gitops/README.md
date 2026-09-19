# Argo-managed desired state

Apply `root.yaml` once to connect Argo CD to `apps/`. It creates one child
Application for each component, which Argo then reconciles from Git.

- `apps/` holds child `Application` manifests.
- `system/` holds cluster-wide configuration such as network policy, secret
  stores, gateways and storage.
- `services/` holds application workloads, one directory per service.

The Cilium, External Secrets and Argo CD releases remain in `../02-platform/`.
They establish GitOps; GitOps does not manage its own bootstrap layer yet.

The `system` project is created first. Its component Applications use it for
cluster-wide configuration and charts; service Applications follow the same
pattern under `apps/services/`.
