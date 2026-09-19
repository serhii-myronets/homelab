# Argo-managed desired state

Each manifest in `apps/` is applied once to connect an Argo CD Application to
its directory. Argo then reconciles that directory from Git.

- `apps/` holds child `Application` manifests.
- `system/` holds cluster-wide configuration such as network policy, secret
  stores, gateways and storage.
- `services/` holds application workloads, one directory per service.

The Cilium, External Secrets and Argo CD releases remain in `../02-platform/`.
They establish GitOps; GitOps does not manage its own bootstrap layer yet.

Apply `apps/system.yaml` once to start reconciliation of the shared resources.
It uses Argo's built-in `default` project only to create the `system` project;
future system applications use that dedicated project.

Apply `apps/metrics-server.yaml` after `system` is Synced. It installs the
official metrics-server Helm chart in `kube-system`.
