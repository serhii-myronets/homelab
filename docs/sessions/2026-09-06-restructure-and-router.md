---
date: 2026-09-06
title: Restructure, backups, and a read-only router review
tags: [portainer, caddy, flood, backup, restic, router, vpn, docs]
hosts: [core, router, proxmox]
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

What the review found stood regardless, and both were real:

- **Samba answered on the public address.** A USB disk at
  `/tmp/mountd/disk1_part1`, shared over SMB, reachable on `50.38.32.155`.
- **VPN clients could not reach the LAN.** `lan → wgserver` existed,
  `wgserver → lan` did not. The peers were already configured correctly, so it
  was one asymmetric forwarding away from working.

Both were closed later the same day — see the end of this record.

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

Then the split went one level further, because two concerns had grown into one
root directory. `core/` is executable and lands on one machine; `docs/` is
descriptive and covers three. `docs/hosts/nas.yaml` became `core.yaml` — the
box serves files, but that is not what makes it matter; it is the one nothing
else may depend on. `proxmox` and `router` kept their names, which already say
what they are. `homelab` was considered for the third and rejected: the router
already has a `network.homelab` — VLAN 10, where Proxmox lives — so the only
host named `homelab` would have been the only one outside it.

Moving `core/` had consequences the repository could not see. Four Portainer
stacks store a compose path, and the systemd backup unit stores an absolute
path to `backup/backup.sh`; both went stale the moment the directories moved.
The unit was repaired by re-running `install.sh`, which regenerates it from
wherever the checkout now lives, and a backup run afterwards exited 0 with
fresh snapshots in both repositories. That failure mode is now a rule in
`AGENTS.md`.

## A third stale fact

`services.yaml` recorded `torrent.home` and `flood.home` as both reaching Flood
on `vpn:3000`. Live, `torrent.home` reached qBittorrent on `vpn:8080` and only
`flood.home` was Flood. The claim came across from the old `inventory.yaml`
unverified and had been carried through two restructures — the same failure as
the two found earlier in the day, and the reason the convention says to check
against the host rather than against another file in this repository.

The routes now read `torrent.home` -> Flood and `qbittorrent.home` -> the raw
interface, and `services.yaml` was checked against the running Caddy rather
than assumed. The commit that made the change, `d7a23ec`, explains it with the
wrong rationale — it repeats the stale fact. The history is not being rewritten
a second time to fix a sentence; this note is the correction.

## Attribution

Thirty-one commits carried a `Co-Authored-By` trailer naming the assistant.
They are gone, and the rule against them is in `AGENTS.md`. Content was
untouched: the rewritten HEAD tree hashes identically to the original,
`7db861a2`.

One mistake worth not repeating: `git add -A` swept an unrelated Caddyfile
edit, made by hand while the rewrite was running, into the commit about
attribution. Stage by path when the working tree is not yours alone.

## Open

The stale Compose labels left by the restructure are closed. A read-only
check of `docker ps -a` on core on 2026-09-06 confirmed that all seven
containers have `working_dir` and `config_files` labels pointing under
`core/`, including `vpn`, `flood`, and `portainer`. The earlier open item here
had not been updated after the redeploys; the closing note below was correct.

Both router problems were closed the same day, by the owner: Samba over WAN in
GL.iNet's interface, and `wgserver2lan` in LuCI — which turned out to be the
right home for it, since GL.iNet exposes no toggle for that forwarding and so
has no state it could drift from. That distinction is now part of
[`0007`](../decisions/0007-router-config-is-not-ours-to-edit.md).

The rest are open on purpose:

- Nothing reports a failure — [`0008`](../decisions/0008-nothing-tells-anyone-when-something-breaks.md), deferred deliberately
- Consolidating onto Proxmox — [`0005`](../decisions/0005-consolidate-to-proxmox.md), paused
- No copy outside the building — [`0006`](../decisions/0006-a-third-copy-on-proxmox.md) closed the machine-loss case only
- 65 of 115 power cycles on Proxmox were unsafe shutdowns

Closed during the session: both router problems, the VLAN 10 DHCP pool moved
off `.100`, the orphaned `omv-compose` cron files, every stale compose label,
the 502 that followed each torrent redeploy, and the third backup copy on
proxmox.
