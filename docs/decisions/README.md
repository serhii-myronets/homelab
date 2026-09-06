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
| [0006](0006-nothing-is-off-box.md) | Nothing is backed up off the box | **open** | backup, risk |

Open items, shortest path first: [0006](0006-nothing-is-off-box.md) is one line
in `backup/backup.sh`; [0005](0005-consolidate-to-proxmox.md) is a project.
