---
title: Decision records
tags: [index, decisions]
---

# Decisions

One file per decision. Front matter carries `status`, `date`, `tags` and the
`hosts` it applies to.

| | Decision | Status | Tags |
|---|---|---|---|
| [0001](0001-portainer-outside-its-own-gitops.md) | Portainer deploys the stacks, nothing deploys Portainer | accepted | portainer, gitops, bootstrap |
| [0002](0002-openmediavault-stays.md) | OpenMediaVault stays, for now | accepted | omv, os, migration |
| [0003](0003-restic-over-omv-rsync.md) | restic, not OMV's rsync | accepted | backup, restic |
| [0004](0004-truenas-ruled-out.md) | TrueNAS SCALE ruled out on hardware | rejected | os, truenas, zfs |
| [0005](0005-consolidate-to-proxmox.md) | Fold everything into the Proxmox box | **open** | consolidation, proxmox, terraform |
| [0006](0006-a-third-copy-on-proxmox.md) | A third copy on the Proxmox box | accepted | backup, restic, sftp |
| [0007](0007-router-config-is-not-ours-to-edit.md) | The router is configured through its own UI, never over ssh | accepted | router, glinet, drift |
| [0008](0008-nothing-tells-anyone-when-something-breaks.md) | Nothing tells anyone when something breaks | **open** | monitoring, alerting, risk |
| [0009](0009-homepage-config-in-git.md) | Keep the Homepage dashboard configuration in git | accepted | homepage, gitops, configuration |
| [0010](0010-wildcard-routing-and-homepage-tabs.md) | Route Kubernetes through a local wildcard and separate dashboard tabs | accepted | caddy, homepage, kubernetes, tls |
| [0011](0011-host-metrics-run-natively.md) | Host metrics run natively under systemd, from `tools/` rather than `core/` | accepted | monitoring, glances, homepage, systemd |
| [0012](0012-the-router-leaves-the-tailnet.md) | The router leaves the tailnet; core and Proxmox advertise the subnets | **proposed** | tailscale, router, glinet, vpn, subnet-routing |

Open items, shortest path first:
[0012](0012-the-router-leaves-the-tailnet.md) is an installer already written
for one host, generalised to two, and two clicks in someone else's UI — until
it is done, the lab is reachable over Tailscale only as far as the Proxmox
host itself. [0008](0008-nothing-tells-anyone-when-something-breaks.md) is a
script and two hooks, waiting on a Telegram bot;
[0005](0005-consolidate-to-proxmox.md) is a project, and paused. Closed on
2026-09-06: both router problems under
[0007](0007-router-config-is-not-ours-to-edit.md), and the missing third backup
copy under [0006](0006-a-third-copy-on-proxmox.md) — which covers losing the
machine, not losing the building. The graphs added under
[0011](0011-host-metrics-run-natively.md) show load, not breakage: they are
read when someone opens the dashboard, so they do not close
[0008](0008-nothing-tells-anyone-when-something-breaks.md).
