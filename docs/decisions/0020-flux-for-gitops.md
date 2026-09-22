---
id: "0020"
title: Flux replaces Argo CD on the Beelink
date: 2026-09-21
status: accepted
tags: [flux, gitops, resources, helm]
hosts: [beelink]
---

# Flux replaces Argo CD on the Beelink

Use Flux for reconciliation of the Beelink's applications and infrastructure.
This replaces the Argo CD choice in [0015](0015-core-talos-platform-bootstrap.md),
while retaining Helmfile for the initial platform bootstrap.

The owner chose to try Flux to reduce the resources spent on GitOps. Keeping
Argo would retain its application UI, but also its API server, repository
server and Redis alongside the application controller. Headlamp already
provides a general cluster console. Flux only needs source, Kustomize and Helm
controllers here; image automation and notifications are not enabled.

The tradeoff is losing Argo's application tree and sync UI. Reconciliation
status is available through Kubernetes resources; Helm charts now have real
Helm releases, with drift detection enabled. Renovate continues proposing
version updates. Headlamp is not an alerting system, so this does not close
[0008](0008-nothing-tells-anyone-when-something-breaks.md).

Bootstrap and health-check procedures live in the
[GitOps README](../../core-talos/03-gitops/README.md). The cutover and its
validation are recorded in the
[migration session](../sessions/2026-09-21-finish-flux-migration.md).
