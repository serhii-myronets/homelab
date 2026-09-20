---
date: 2026-09-19
title: Right-size Argo CD controller concurrency
tags: [beelink, kubernetes, argocd, resources, helmfile]
---

The single-node cluster has 19 Argo CD Applications. Its application controller
used about 273 MiB while the default status and operation worker counts were 20
and 10. The other active Argo components together used about 112 MiB.

`02-platform/values/argocd-values.yaml` now sets two status workers and one
operation worker. The Argo Helm chart renders those values into
`argocd-cmd-params-cm`; changing its checksum rolls the controller. Helmfile
applied the Argo release successfully, and every Application remained Synced
and Healthy. After the rollout the controller held 213 MiB, a 60 MiB reduction
at idle. This is an observed sample, not a fixed memory guarantee.

`helmfile apply --selector name=argocd` still runs the configured `prepare`
hook first, so it re-applied the platform bootstrap resources as expected. The
existing Helmfile hook trap covers this behavior.
