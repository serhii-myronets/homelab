---
id: "0031"
title: The cluster is core; the old box is satellite
date: 2026-09-29
status: accepted
tags: [naming, core, satellite, beelink, repository, flux]
---

# The cluster is core; the old box is satellite

`core` named the OpenMediaVault box and promised it would be the one machine
nothing depends on. The Talos cluster on the Beelink has since taken over
everything that box did - the services, the files, the backups to R2 - and
everything in the house now depends on it. So the name moves with the job:
the cluster is `core`, deployed from `core/`, and the old box is `satellite`,
to be rebuilt on Talos to watch core from outside and keep copies of its
backups. The promise that nothing may depend on it goes with satellite.

Machines are named for their role, not their hardware or what they run.
`beelink` broke that, and `core-talos/` read as "core, but on Talos" once
core was itself going to run Talos.

Rejected names: `prod`, `ops` and `lab` - the owner did not want them;
`home` would have collided with the `*.home` domain. For the old box,
`witness` was the close alternative; `satellite` won as the pair to `core`.

A `clusters/` directory was rejected too. It earns its level with three
clusters or shared bases; this repository will hold two, and the lab on
Proxmox lives elsewhere. Each cluster sits at the root, as `core/` did.

## What moved and what did not

`core-talos/` became `core/`, and the old `core/` Docker stacks went to
`archive/core-docker/`, in one commit. Flux was kept safe by checking
`flux diff kustomization root --path ./core/03-gitops/apps` first - 20 child
Kustomizations, only `spec.path` changing, nothing created or deleted - and
applying `core/03-gitops/flux.yaml` by hand straight after the push, since the
root Kustomization is not reconciled from Git. Renovate's rule disabling
`core/**`, meant for the Docker stacks, would have silenced every update to
the cluster; it now disables `archive/**`.

Not renamed, because they are identifiers in live systems rather than labels
here: the Talos cluster name `beelink`, the Cloudflare tunnel `beelink`, the
R2 prefix `etcd/beelink`, the Proxmox hostname. They change only when the
thing they name is rebuilt. Sessions and decisions before this one keep the
old names; their links to host files were repointed so they still land on the
right machine.
