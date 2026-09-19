# core-talos

The future replacement for `core/`, running Talos directly on ME Pro. The
existing OpenMediaVault deployment remains in `core/` during migration.

- [`01-talos/`](01-talos/): Terraform-managed Talos configuration, local credentials and cluster initialization.
- [`02-platform/`](02-platform/): Helmfile bootstrap for Cilium, External Secrets and Argo CD.
- [`03-gitops/`](03-gitops/): Argo root application, cluster configuration and services.

Current status: the single-node Beelink cluster and its initial platform are running.
