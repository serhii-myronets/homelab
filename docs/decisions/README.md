---
title: Decision records
tags: [index, decisions]
---

# Decisions

One file per decision still in force, or still open. Front matter carries
`status`, `date` and `tags`. Decisions about setups that no longer exist -
OpenMediaVault, Portainer, Caddy, Homepage, Pulse, Tailscale, the satellite
cluster - were removed on 2026-09-30; git history keeps them, and numbers
are not reused.

| | Decision | Status | Tags |
|---|---|---|---|
| [0007](0007-router-config-is-not-ours-to-edit.md) | The router is configured through its own UI, never over ssh | accepted | router, glinet, openwrt, drift |
| [0008](0008-nothing-tells-anyone-when-something-breaks.md) | Nothing tells anyone when something breaks | **open** | monitoring, alerting, healthchecks, telegram |
| [0014](0014-terraform-for-core-talos.md) | Manage core's Talos bootstrap with Terraform | accepted | talos, terraform, bootstrap, secrets |
| [0015](0015-core-talos-platform-bootstrap.md) | Bootstrap the platform with Helmfile and External Secrets | accepted | talos, kubernetes, helmfile, cilium, external-secrets, infisical |
| [0016](0016-beelink-media-disks.md) | Keep the HDDs as two XFS volumes behind static local PVs | accepted | talos, kubernetes, storage, hdd, media |
| [0018](0018-renovate-for-pinned-versions.md) | Keep pinned versions current with Renovate | accepted | renovate, gitops, versions, flux |
| [0019](0019-beelink-backups-to-r2.md) | Back up to R2, and let volumes restore themselves | accepted | backup, volsync, lvm, openebs, r2 |
| [0020](0020-flux-for-gitops.md) | Flux replaces Argo CD | accepted | flux, gitops, resources, helm |
| [0021](0021-flux-operator-for-the-web-interface.md) | The Flux Operator installs Flux, for its web interface | accepted | flux, gitops, ui |
| [0022](0022-uptime-kuma-on-beelink.md) | Uptime Kuma observes core from inside it | superseded by 0036; archived | monitoring, uptime-kuma, alerts |
| [0023](0023-archive-paperless.md) | Archive the empty Paperless trial | accepted | paperless, archive |
| [0024](0024-keep-volsyncs-restore-volume.md) | Keep VolSync's restore volume instead of cleaning it up | accepted | volsync, openebs, backup, restore |
| [0025](0025-one-namespace-for-the-storage-controllers.md) | One namespace for the storage controllers, and why OpenEBS is not in it | accepted | storage, openebs, volsync, namespaces |
| [0026](0026-sure-goes-public-for-plaid.md) | Publish Sure so Plaid can reach it | accepted | sure, plaid, cloudflare, finance |
| [0027](0027-archive-actual.md) | Archive Actual Budget; Sure keeps the budgets | accepted | actual, sure, finance, archive |
| [0028](0028-beelink-address-is-static.md) | Node addresses are set in Talos, not reserved on the router | accepted | talos, network, dhcp, router |
| [0029](0029-swap-on-the-system-disk.md) | Swap on the system disk, behind zswap | accepted | talos, swap, zswap, memory |
| [0030](0030-nightly-etcd-backup-with-restic.md) | Back etcd up nightly with talosctl and restic | accepted | talos, etcd, backup, restic, r2 |
| [0034](0034-satellite-joins-core.md) | The old box is core's worker, not a cluster of its own | accepted | worker-1, core, talos, memory |
| [0035](0035-worker-1-holds-nothing-volsync-backs-up.md) | worker-1 holds nothing that VolSync backs up | accepted | worker-1, volsync, storage, scheduling |
| [0037](0037-terraform-state-in-r2.md) | Terraform state in R2 and secrets.yaml in Infisical, where the cluster can read them | accepted | terraform, talos, r2, secrets |
| [0039](0039-home-served-by-bind-on-the-router.md) | .home is served by BIND on the router, written by each cluster's external-dns | accepted | router, dns, bind, external-dns |
| [0036](0036-gatus-on-the-router.md) | Gatus and a metrics exporter run on the router, installed over ssh | accepted | router, gatus, monitoring |

Open: [0008](0008-nothing-tells-anyone-when-something-breaks.md) - nothing
reports a failure to anyone yet.
