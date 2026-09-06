# Working in this repository

Homelab configuration for two machines. Start with
[`docs/inventory.yaml`](docs/inventory.yaml) — every hard fact about hardware,
network, stacks, routes and backups is there as data, verified against the live
hosts. Reasoning lives in [`docs/decisions/`](docs/decisions/), one file per
decision with tags and status in front matter.

## Layout

| Path | |
|---|---|
| `<stack>/docker-compose.yaml` | one directory per stack, at the root |
| `bootstrap.sh` | bare host → Portainer running; idempotent |
| `backup/` | restic script, installer, systemd units |
| `docs/inventory.yaml` | the facts |
| `docs/decisions/` | why things are the way they are |

## Access

Both hosts take the key at `~/.ssh/id_ed25519`:

```bash
ssh root@192.168.8.100   # nas
ssh root@10.1.1.100      # proxmox
```

The Proxmox box also answers unauthenticated on
`http://10.1.1.100:8008/api/*` (ProxMenux Monitor) — handy for hardware and
guest facts without a login.

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
errors found on 2026-09-06 were both stale claims that read as true. Compose
files validate with `docker compose config`; the Caddyfile validates with
`caddy validate` in a throwaway container on the NAS, since there is no Docker
daemon locally.

Comments earn their place by saying something the code does not. Prefer
recording a decision in `docs/decisions/` over explaining it inline twice.
