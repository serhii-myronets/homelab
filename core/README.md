# core

The cluster where the services and their data live, and what everything in
the house depends on: Talos on two nodes, `controlplane` on the Beelink ME Pro
at `192.168.8.10` and `worker-1` on the old OpenMediaVault box at `.11`. See
`../docs/hosts/`.

- [`01-talos/`](01-talos/): Terraform-managed Talos configuration, local credentials and cluster initialization.
- [`02-platform/`](02-platform/): Helmfile bootstrap for Cilium, External Secrets and the Flux Operator, plus the `FluxInstance` that installs the Flux controllers.
- [`03-gitops/`](03-gitops/): Flux root Kustomization, cluster configuration and services.
