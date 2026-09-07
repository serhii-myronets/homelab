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

Open items, shortest path first:
[0008](0008-nothing-tells-anyone-when-something-breaks.md) is a script and two
hooks, waiting on a Telegram bot; [0005](0005-consolidate-to-proxmox.md) is a
project, and paused. Closed on 2026-09-06: both router problems under
[0007](0007-router-config-is-not-ours-to-edit.md), and the missing third backup
copy under [0006](0006-a-third-copy-on-proxmox.md) — which covers losing the
machine, not losing the building.
