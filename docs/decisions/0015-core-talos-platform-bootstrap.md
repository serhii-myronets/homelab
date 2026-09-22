---
id: "0015"
title: Bootstrap the Beelink platform with Helmfile and External Secrets
date: 2026-09-18
status: accepted
tags: [talos, kubernetes, helmfile, argocd, cilium, external-secrets, infisical]
---

# Bootstrap the Beelink platform with Helmfile and External Secrets

The GitOps controller choice below is superseded by
[0020](0020-flux-for-gitops.md). The Helmfile bootstrap boundary remains.

`01-talos/` owns Talos machine configuration and the one-time Kubernetes
bootstrap. `02-platform/` owns the in-cluster foundation: Cilium, External
Secrets and Argo CD, installed in that order by Helmfile.

External Secrets remains part of the initial platform. Its Infisical machine
credential is the unavoidable first secret, stored only in the ignored
`02-platform/prepare-hook/initial-secret.yaml`; the tracked example records its
shape. The External Secrets Helm chart owns its CRDs, so controller and CRD
versions are installed together.

Gateway API CRDs are installed before Cilium because Cilium Gateway API is
enabled. L2 announcements remain enabled for future LAN service addresses.

Argo CD stays anonymously accessible with administrator permissions on the
LAN, as requested by the owner. Its CRDs are installed by the pinned chart.

Prometheus Operator, VictoriaMetrics Operator, Strimzi, cert-manager and the
Cilium Hubble Relay/UI are deferred. They have no current workload and add
controllers, CRDs or persistent resource use. Each can be added when the
first application needs it.
