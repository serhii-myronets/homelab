# Working in this repository

Homelab configuration for three machines. Start with
[`docs/index.yaml`](docs/index.yaml): it maps a question to the one file that
answers it, so a lookup costs one read rather than a search. Facts are YAML and
verified against the live hosts; reasoning is Markdown with YAML front matter
under [`docs/decisions/`](docs/decisions/); what happened and why it was tried
is in [`docs/sessions/`](docs/sessions/), newest last — read it before starting
work.

## Layout

| Path | |
|---|---|
| `<stack>/docker-compose.yaml` | one directory per stack, at the root |
| `bootstrap.sh` | bare host → Portainer running; idempotent |
| `backup/` | restic script, installer, systemd units |
| `docs/index.yaml` | which file answers which question |
| `docs/hosts/*.yaml` | one file per machine |
| `docs/network.yaml` | subnets, DNS, TLS, what can reach what |
| `docs/services.yaml` | stacks, routes, where the secrets live |
| `docs/backups.yaml` | repositories, coverage, gaps |
| `docs/decisions/` | why things are the way they are |
| `docs/sessions/` | what was done, and what was tried and failed |

## Access

All three take the key at `~/.ssh/id_ed25519`:

```bash
ssh root@192.168.8.100   # nas
ssh root@10.1.1.100      # proxmox
ssh root@192.168.8.1     # router — read-only, see below
```

The Proxmox box also answers unauthenticated on
`http://10.1.1.100:8008/api/*` (ProxMenux Monitor) — handy for hardware and
guest facts without a login.

**The router is read-only over ssh.** GL.iNet's firmware regenerates uci from
its own state, so a change made here can be invisible in the UI or reverted
without warning. Gather facts, write them to `docs/hosts/router.yaml`, and
describe fixes as UI steps — never apply them. See
[`decisions/0007`](docs/decisions/0007-router-config-is-not-ours-to-edit.md).

## Things that will bite

**Editing a bind-mounted file is not enough.** Mounting a single file pins its
inode, and git replaces files rather than editing them, so *Pull and redeploy*
leaves the container reading the old content. Compose will not recreate it
either, because the service definition did not change. `docker restart caddy`
after any Caddyfile change.

**`.home` hostnames need `tls internal`.** Without it Caddy asks Let's Encrypt
for a certificate, gets rejected because `.home` is not a real TLD, and retries
for thirty days — putting the account that issues the real `serhii.link`
certificates at risk of a rate limit.

**Portainer's "Additional paths" takes compose files, not any file.** A
`Caddyfile` there fails the deploy with `top-level object must be a mapping`.

**"Enable relative path volumes" is offered only when a stack is created.** Any
stack that bind-mounts a file out of this repo needs it, or Portainer resolves
the path inside its own container, the daemon creates an empty directory there
instead, and the mount fails with `ENOTDIR`.

**Flood runs as uid 1001** and ignores `PUID`/`PGID`. Its data directory has to
be owned by `1001:1001`, which `bootstrap.sh` handles.

## Conventions

Verify against the live host before writing a fact down — the two documentation
errors found on 2026-09-06 were both stale claims that read as true. A fact
belongs in exactly one file; if it is already in `docs/hosts/`, link to it
rather than restating it. Close a working session by adding to
`docs/sessions/`. Compose
files validate with `docker compose config`; the Caddyfile validates with
`caddy validate` in a throwaway container on the NAS, since there is no Docker
daemon locally.

Comments earn their place by saying something the code does not. Prefer
recording a decision in `docs/decisions/` over explaining it inline twice.
