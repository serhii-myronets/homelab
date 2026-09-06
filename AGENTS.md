# Working in this repository

Three machines:

| | | Deployed from here |
|---|---|---|
| **core** | the one nothing else may depend on — services, files, backups | yes, out of `core/` |
| **proxmox** | built and destroyed on purpose — Talos, Terraform | no |
| **router** | the boundary with the internet — routing, DNS, firewall, VPN | no, and never over ssh |

The repository has two halves and the split is the point. `core/` is
*executable*: compose files, the bootstrap and the backup job, deployed onto
one machine. `docs/` is *descriptive*: what all three machines are, why, and
what has already gone wrong. Changing one should rarely mean changing the
other.

**Read [`docs/index.yaml`](docs/index.yaml) first.** It maps a question to the
one file that answers it, so a lookup costs one read rather than a search.
Before debugging anything that should work, check
[`docs/traps.yaml`](docs/traps.yaml) — it lists failures already paid for once.

| Path | |
|---|---|
| `core/<stack>/docker-compose.yaml` | one directory per stack |
| `core/bootstrap.sh` | bare host → Portainer running; idempotent |
| `core/backup/` | restic script, installer, systemd units |
| `docs/` | every fact, decision and session; `index.yaml` routes |

Each half carries its own README: the root one describes the repository,
`core/README.md` is the operational manual, `docs/README.md` indexes the facts.
A procedure belongs in one of those, never in two.

## Access

All three take the key at `~/.ssh/id_ed25519`:

```bash
ssh root@192.168.8.100   # core
ssh root@10.1.1.100      # proxmox
ssh root@192.168.8.1     # router — read-only, see rules
```

`proxmox` also answers unauthenticated on `http://10.1.1.100:8008/api/*`
(ProxMenux Monitor) — hardware and guest facts without a login.

## Rules

**Verify before writing a fact down.** Both documentation errors found on
2026-09-06 were stale claims that read as true. Facts come from the live host,
not from memory or from another file in this repo.

**A fact belongs in exactly one file.** If it is already in `docs/`, link to
it. `README.md` is procedures for a human; it must not restate the tables.

**Never change the router over ssh.** GL.iNet's firmware regenerates uci from its
own state, so a change made there can be invisible in its UI or silently
reverted. Gather facts read-only, write them to `docs/hosts/router.yaml`, and
describe fixes as UI steps for a human. See
[`decisions/0007`](docs/decisions/0007-router-config-is-not-ours-to-edit.md).

**Ask before touching anything stateful.** Deleting data, wiping a repository,
rebooting a host and destroying a Proxmox guest are the user's call, not a
step in a plan.

**Moving anything under `core/` has consequences off the repository.** Four
Portainer stacks store a compose path, and the systemd backup unit stores an
absolute path to `core/backup/backup.sh`. Rename a directory here and both go
stale — say so, and say which.

**Record what you learn.** A new failure mode goes in `docs/traps.yaml`; a
choice with a rejected alternative goes in `docs/decisions/`; the narrative of
a working session goes in `docs/sessions/`, including what was tried and
failed.

**Read only the newest session.** Older ones are history — anything from them
that still matters has already graduated into `docs/`, a decision, or a trap.

## Validating

Compose files: `docker compose config`. The Caddyfile: `caddy validate` in a
throwaway container on the NAS, since there is no Docker daemon locally. YAML
under `docs/` must parse; front matter must carry `tags`.

Comments earn their place by saying something the code does not.
