# core-talos

The future replacement for `core/`, running Talos directly on ME Pro. The
existing OpenMediaVault deployment remains in `core/` during migration.

- [`talos/`](talos/): Terraform-managed Talos configuration, local credentials and cluster initialization.
- [`platform/`](platform/): Helmfile bootstrap for Cilium, External Secrets and Argo CD.
- [`gitops/`](gitops/): Argo root application, cluster configuration and services.

Current status: the single-node Beelink cluster and its initial platform are running.
