---
title: Decision records
tags: [index, decisions]
---

# Decisions

One file per decision. Front matter carries `status`, `date`, `tags` and the
`hosts` it applies to.

| | Decision | Status | Tags |
|---|---|---|---|
| [0001](0001-portainer-outside-its-own-gitops.md) | Portainer deploys the stacks, nothing deploys Portainer | accepted | portainer, gitops, deployment, bootstrap |
| [0002](0002-openmediavault-stays.md) | OpenMediaVault stays, for now | accepted | omv, os, gitops, migration |
| [0003](0003-restic-over-omv-rsync.md) | restic, not OMV's rsync | accepted | backup, restic, omv, disaster-recovery |
| [0004](0004-truenas-ruled-out.md) | TrueNAS SCALE ruled out on hardware | rejected | os, truenas, zfs, hardware |
| [0005](0005-consolidate-to-proxmox.md) | Fold everything into the Proxmox box | **open** | consolidation, proxmox, lxc, terraform, gitops |
| [0006](0006-a-third-copy-on-proxmox.md) | A third copy on the Proxmox box | accepted | backup, disaster-recovery, restic, sftp |
| [0007](0007-router-config-is-not-ours-to-edit.md) | The router is configured through its own UI, never over ssh | accepted | router, glinet, openwrt, drift, vpn, firewall |
| [0008](0008-nothing-tells-anyone-when-something-breaks.md) | Nothing tells anyone when something breaks | **open** | monitoring, alerting, smart, backup, telegram, risk |
| [0009](0009-homepage-config-in-git.md) | Keep the Homepage dashboard configuration in git | accepted | homepage, gitops, configuration |
| [0010](0010-wildcard-routing-and-homepage-tabs.md) | Route Kubernetes through a local wildcard and separate dashboard tabs | accepted | caddy, homepage, kubernetes, tls |
| [0011](0011-host-metrics-run-natively.md) | Host metrics run natively under systemd, from tools/ rather than core/ | superseded | monitoring, glances, homepage, systemd |
| [0012](0012-the-router-leaves-the-tailnet.md) | The router leaves the tailnet; core and Proxmox advertise the subnets | withdrawn | tailscale, router, glinet, vpn, subnet-routing, zerotier, dns |
| [0013](0013-pulse-replaces-glances.md) | Pulse replaces Glances as the infrastructure monitor | accepted | monitoring, pulse, docker, proxmox, homepage |
| [0014](0014-terraform-for-core-talos.md) | Manage the replacement core bootstrap with Terraform | accepted | talos, terraform, bootstrap, secrets |
| [0015](0015-core-talos-platform-bootstrap.md) | Bootstrap the Beelink platform with Helmfile and External Secrets | accepted | talos, kubernetes, helmfile, argocd, cilium, external-secrets, infisical |
| [0016](0016-beelink-media-disks.md) | Keep the Beelink HDDs as two XFS volumes behind static local PVs | accepted | beelink, talos, kubernetes, storage, hdd, media |
| [0017](0017-beelink-nvme-split-and-static-config-volumes.md) | Split the Beelink NVMe and keep configurations on static volumes | superseded by 0019 | beelink, talos, kubernetes, storage, nvme, openebs |
| [0018](0018-renovate-for-pinned-versions.md) | Keep the Beelink's pinned versions current with Renovate | accepted | beelink, renovate, gitops, versions |
| [0019](0019-beelink-backups-to-r2.md) | Back the Beelink up to R2, and let its volumes restore themselves | accepted | beelink, backup, volsync, cloudnative-pg, lvm, openebs, r2 |
| [0020](0020-flux-for-gitops.md) | Flux replaces Argo CD on the Beelink | accepted | flux, gitops, resources, helm |
| [0021](0021-flux-operator-for-the-web-interface.md) | The Flux Operator installs Flux, for its web interface | accepted | flux, gitops, ui, resources |
| [0022](0022-uptime-kuma-on-beelink.md) | Uptime Kuma observes the Beelink from inside it | accepted | monitoring, uptime-kuma, beelink, alerts |
| [0023](0023-archive-paperless.md) | Archive the empty Paperless trial | accepted | beelink, paperless, documents, storage, archive |
| [0024](0024-keep-volsyncs-restore-volume.md) | Keep VolSync's restore volume instead of cleaning it up | accepted | beelink, volsync, openebs, backup, storage, restore |
| [0025](0025-one-namespace-for-the-storage-controllers.md) | One namespace for the storage controllers, and why OpenEBS is not in it | accepted | beelink, kubernetes, storage, openebs, volsync, namespaces, helm |
| [0026](0026-sure-goes-public-for-plaid.md) | Publish Sure so Plaid can reach it, and drop the other two providers | accepted | beelink, sure, plaid, snaptrade, simplefin, cloudflare, privacy, finance |

Open items, shortest path first:
[0008](0008-nothing-tells-anyone-when-something-breaks.md) is a
script and two hooks, waiting on a Telegram bot;
[0005](0005-consolidate-to-proxmox.md) is a project, and paused. Closed on
2026-09-06: both router problems under
[0007](0007-router-config-is-not-ours-to-edit.md), and the missing third backup
copy under [0006](0006-a-third-copy-on-proxmox.md) — which covers losing the
machine, not losing the building. The graphs added under
[0011](0011-host-metrics-run-natively.md) show load, not breakage: they are
read when someone opens the dashboard, so they do not close
[0008](0008-nothing-tells-anyone-when-something-breaks.md). Neither does the
Flux web interface added under
[0021](0021-flux-operator-for-the-web-interface.md), for the same reason - but
the controller that could send an alert now runs, which is the first half of
closing it.
