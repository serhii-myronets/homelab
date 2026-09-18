---
date: 2026-09-18
title: Simplify local files for the ME Pro bootstrap
tags: [talos, terraform, bootstrap, secrets]
---

The cluster had been installed and bootstrapped successfully. Talos v1.14.1
answered with RBAC enabled, and the Terraform state contained the machine
configuration, bootstrap and kubeconfig resources.

Removed the plan helper and generated plan, rendered machine config and local
copies of client configs. The active Talos and Kubernetes configs already live
in their standard user paths with the `me-pro` contexts.

Moved the local state, its backup and the original secrets bundle directly
under `core-talos/bootstrap/`. They remain plaintext and ignored by Git. The
explicit local backend was removed, restoring Terraform's default state path.

The owner chose Cilium with kube-proxy replacement for the next clean
bootstrap. Added the Talos 1.14 CNI patch, which deletes Flannel and disables
kube-proxy. Helm installation was explicitly deferred; no Cilium workload or
Talos configuration was applied during this preparation.

The owner later chose a small initial platform for the Beelink: Cilium,
External Secrets backed by Infisical, and Argo CD. Argo remains anonymously
accessible with administrator permissions on the LAN. Gateway API CRDs stay
because Cilium Gateway API is enabled; unused monitoring, Kafka, certificate
and VictoriaMetrics operators were removed from the initial bootstrap.

While validating the Helmfile, `helmfile build` ran its `prepare` hook. It
created the `external-secrets` namespace, applied Gateway API CRDs and applied
the local Infisical credential to the live Beelink cluster. It did not install
any Helm release. The behaviour is recorded in `docs/traps.yaml`.

Before the first Helm installation, Cilium was pinned to 1.20.2 and Argo CD to
chart 10.9.2. External Secrets remains at 2.10.0; its admission webhook and
certificate controller are disabled because CRD conversion is disabled. Its
single controller is limited to 100m CPU and 128Mi memory.

The generated Talos config retained its default installation path `/dev/sda`
alongside the NVMe selector. The node was verified to run its EPHEMERAL volume
from `/dev/nvme0n1p4`; the control-plane patch now explicitly selects
`/dev/nvme0n1` as well, protecting the two 10 TB HDDs during a later install.
