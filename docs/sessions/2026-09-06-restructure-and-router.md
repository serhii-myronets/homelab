---
date: 2026-09-06
title: Restructure, backups, and a read-only router review
tags: [portainer, caddy, flood, backup, restic, router, vpn, docs]
hosts: [nas, router, proxmox]
decisions: [0001, 0002, 0003, 0004, 0005, 0006, 0007]
---

# 2026-09-06

A long session that moved from debugging a stack deployment to auditing the
whole setup.

## Portainer stopped deploying

Two failures, two different causes, both worth remembering.

`top-level object must be a mapping` came from putting the `Caddyfile` in
Portainer's **Additional paths**. That field takes *additional compose files*
and merges them with `-f`; a non-YAML file there fails the parse. Reproduced
locally with `docker compose -f docker-compose.yaml -f Caddyfile config`. The
field has to stay empty.

`ENOTDIR` came from the `./Caddyfile` bind mount without **Enable relative path
volumes**. Portainer resolved the path inside its own container, the daemon
could not see it, created an empty directory in its place, and the mount failed
against what was now a directory. Proved with `stat` on both sides. The option
is offered only when a stack is *created*, never when editing one.

Then a third: edits landed in git, the stack redeployed, and the container kept
serving the old content. Bind-mounting a single file pins its inode; git
replaces files rather than editing them. Host inode 76032888/1049 B against
container inode 76036078/1103 B. `docker restart caddy` after any Caddyfile
change.

## Flood

`FLOOD_DISABLE_AUTH` is not a flag. Flood maps `FLOOD_OPTION_<name>` onto its
CLI flags through yargs, so each name has to match a real flag exactly —
`QBURL`, not `QBIT_URL`, and anything unrecognised is ignored in silence. The
working set is `AUTH=none`, `RUNDIR`, `QBURL`, `QBUSER`, `QBPASS`. The last two
look redundant, since qBittorrent trusts 127.0.0.1 through its
`AuthSubnetWhitelist`, but a test container without them exits 1 with Zod
errors: they are structurally required.

## Backups

Started as one repository, ended as two after a better scheme was proposed:
each disk holds the backup of what lives on the other, so losing either leaves
a copy on the survivor. The first attempt backed sda's data onto sda, which
protects against nothing.

First snapshot was 1.7 GB. `jellyfin/config/metadata` — artwork a library scan
downloads again. Excluded, along with `cache` and `log`: 133 MB. `library.db`
stays, because watch history and users do not come back.

Restores verified in both directions. The OS-reinstall case needs
`mount /dev/sda1 /mnt/d` by hand first, because the mount definition lives in
`config.xml` which lives on the disk being mounted.

Dropped from the backup set after discussion: `/etc/apt` (bootstrap installs
Docker) and `/etc/ssh` (documenting `ssh-copy-id` is honest, restoring host keys
is not).

## Housekeeping

Removed ~1.7 GB of dead data directories and the vestigial
`/srv/ssd/docker/compose/` tree. Migrated Portainer off OMV's compose plugin;
its labels now point at the repo checkout. Flattened `stacks/` to the root.
Enabled SMART monitoring — the devices were marked monitored while the global
`<smart><enable>0</enable>` toggle was off, so nothing was actually polling.

## The router

Reviewed read-only, and then not read-only, which was the mistake of the
session. Three uci changes were made directly — two to close Samba on the WAN
address, one to add a `wgserver → lan` forwarding — before the instruction came
to leave the firmware's own rules alone. All three were reverted the same day
and the reasoning is now [`0007`](../decisions/0007-router-config-is-not-ours-to-edit.md).

What the review found stands regardless, and both items are live:

- **Samba answers on the public address.** A USB disk at
  `/tmp/mountd/disk1_part1`, shared over SMB, reachable on `50.38.32.155`.
- **VPN clients cannot reach the LAN.** `lan → wgserver` exists,
  `wgserver → lan` does not. The peers are already configured correctly, so
  this is one asymmetric forwarding away from working.

## Wrong turns worth not repeating

Portainer clones the whole repository, not just the compose file. Moving
Portainer to a different network was suggested on the theory that an `edge`
network existed; it never did, and the edit was reverted before it did harm.
Adding the `Caddyfile` to Additional paths was advised before it was understood
to be the cause of the failure.

## The documentation itself

Split `inventory.yaml` into one file per machine, and then found the split had
not gone far enough: `README.md` still carried the routes table, the backup
table and three of the traps, all of which now lived in `docs/` as well. That
is exactly the mechanism behind the two stale facts found earlier in the day.
README is now procedures for a human and links out for everything else.

The operational traps moved to `docs/traps.yaml` as data, and the entry point
was cut to routing and rules. It is `AGENTS.md` — the convention several tools
read, and one file rather than a per-vendor one. The repository was renamed
from `homelab-docker-stack` to `homelab` at the same time: it stopped being
only Docker stacks some time ago.

## Open

- `wgserver → lan` forwarding, from the GL.iNet UI — [`0007`](../decisions/0007-router-config-is-not-ours-to-edit.md)
- Samba over WAN, from the GL.iNet UI — [`0007`](../decisions/0007-router-config-is-not-ours-to-edit.md)
- Nothing is backed up off the box — [`0006`](../decisions/0006-nothing-is-off-box.md)
- Consolidating onto Proxmox — [`0005`](../decisions/0005-consolidate-to-proxmox.md)
- SMART has no alert recipient
- Proxmox sits inside the VLAN 10 DHCP pool without a reservation
- Orphaned `/etc/cron.d/omv-compose-*` on the NAS
