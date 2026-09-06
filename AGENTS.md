# Working in this repository

Homelab configuration and documentation for three machines: a NAS running the
services, a Proxmox box used as a lab, and the router in front of both.

**Read [`docs/index.yaml`](docs/index.yaml) first.** It maps a question to the
one file that answers it, so a lookup costs one read rather than a search.
Before debugging anything that should work, check
[`docs/traps.yaml`](docs/traps.yaml) — it lists failures already paid for once.

| Path | |
|---|---|
| `<stack>/docker-compose.yaml` | one directory per stack, at the root |
| `bootstrap.sh` | bare host → Portainer running; idempotent |
| `backup/` | restic script, installer, systemd units |
| `docs/` | every fact, decision and session; `index.yaml` routes |

## Access

All three take the key at `~/.ssh/id_ed25519`:

```bash
ssh root@192.168.8.100   # nas
ssh root@10.1.1.100      # proxmox
ssh root@192.168.8.1     # router — read-only, see rules
```

Proxmox also answers unauthenticated on `http://10.1.1.100:8008/api/*`
(ProxMenux Monitor) — hardware and guest facts without a login.

## Rules

**Verify before writing a fact down.** Both documentation errors found on
2026-09-06 were stale claims that read as true. Facts come from the live host,
not from memory or from another file in this repo.

**A fact belongs in exactly one file.** If it is already in `docs/`, link to
it. `README.md` is procedures for a human; it must not restate the tables.

**Never change the router over ssh.** GL.iNet's firmware regenerates uci from
its own state, so a change made there can be invisible in its UI or silently
reverted. Gather facts read-only, write them to `docs/hosts/router.yaml`, and
describe fixes as UI steps for a human. See
[`decisions/0007`](docs/decisions/0007-router-config-is-not-ours-to-edit.md).

**Ask before touching anything stateful.** Deleting data, wiping a repository,
rebooting a host and destroying a Proxmox guest are the user's call, not a
step in a plan.

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
