---
id: "0018"
title: Keep pinned versions current with Renovate
date: 2026-09-19
status: accepted
tags: [renovate, gitops, versions, flux]
---

# Keep pinned versions current with Renovate

Revised 2026-10-02 for Flux and `core/`.

Every image, chart and version under `core/` and `router/` is pinned, so a
rebuild reproduces the same cluster. Renovate proposes their updates as pull
requests; merging one under `core/03-gitops/` lets Flux deploy it. Its
configuration is `renovate.json5` at the repository root, and the GitOps
README shows how to try it locally.

It runs as Mend's hosted GitHub App. From 2026-09-19 to 2026-10-02 the
configuration sat here with the App never installed, and no one noticed:
nothing in the repository shows whether Renovate runs. Its pull requests and
the Dependency Dashboard issue do.

What Flux deploys by itself arrives as one weekly pull request before Monday
morning; majors come one by one. Helmfile releases, the Gateway API CRDs and
Gatus on the router get their own pull requests, noting that merging does
not deploy them. Talos, Kubernetes, the Talos Terraform provider and a
Postgres major wait on the Dependency Dashboard until approved there,
because each is a procedure rather than a new tag. Nothing merges itself.

Renovate commits under the owner's name and adds no footer to its pull
requests, keeping the history to one author.

## Rejected

- **Dependabot.** Built into GitHub, but it reads neither Flux HelmReleases
  nor Helmfile, which hold most of the versions here.
- **Renovate run by GitHub Actions or a CronJob in the cluster.** More
  control over when it runs, for a token with write access to keep - in the
  cluster, readable by anything that reaches External Secrets
  (decisions/0037).
- **Flux's image automation.** It commits to main without a pull request and
  understands none of the composite tags the rules here decode.
- **version-checker or WUD** for a view of what is out of date. The
  Dependency Dashboard is that view; WUD watches Docker hosts, not
  Kubernetes.
