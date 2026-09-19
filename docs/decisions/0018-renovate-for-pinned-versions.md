---
id: "0018"
title: Keep the Beelink's pinned versions current with Renovate
date: 2026-09-19
status: accepted
tags: [beelink, renovate, gitops, versions]
---

# Keep the Beelink's pinned versions current with Renovate

Every image, chart and remote base under `core-talos/` is pinned, so a
reinstall reproduces the same cluster. Renovate, as the GitHub App, proposes
their updates as pull requests; merging one lets Argo deploy it. Its
configuration is `renovate.json5` at the repository root.

Updates Argo deploys by itself arrive as one weekly pull request, before
Monday morning. Helmfile releases and the Gateway API CRDs get their own pull
requests, noting that merging does not deploy them. Talos, Kubernetes and the
Talos Terraform provider only appear on the dependency dashboard until
approved there, because upgrading them is a procedure rather than a version
change. `core/` is excluded: it follows floating tags and is being retired.

Renovate commits under the owner's name and adds no footer to its pull
requests, keeping the history to one author.

Dependabot was the alternative. It is built into GitHub but does not read Argo
CD Applications, Helmfile or remote Kustomize bases, which hold most of the
versions here.
