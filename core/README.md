# core

The cluster where the services and their data live: Talos on the Beelink ME
Pro at `192.168.8.10`. Everything in the house depends on it; what watches it
from outside belongs on `satellite`. Its Talos cluster is still named `beelink`
inside - see `../docs/hosts/core.yaml`.

- [`01-talos/`](01-talos/): Terraform-managed Talos configuration, local credentials and cluster initialization.
- [`02-platform/`](02-platform/): Helmfile bootstrap for Cilium, External Secrets and the Flux Operator, plus the `FluxInstance` that installs the Flux controllers.
- [`03-gitops/`](03-gitops/): Flux root Kustomization, cluster configuration and services.
