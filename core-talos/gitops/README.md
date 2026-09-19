# Argo-managed desired state

`root.yaml` will be applied once to connect Argo CD to this directory.
Everything below then reconciles from Git.

- `apps/` holds child `Application` manifests.
- `system/` holds cluster-wide configuration such as network policy, secret
  stores, gateways and storage.
- `services/` holds application workloads, one directory per service.

The Cilium, External Secrets and Argo CD releases remain in `../platform/`.
They establish GitOps; GitOps does not manage its own bootstrap layer yet.
