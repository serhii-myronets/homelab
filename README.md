# homelab-docker-stack

Docker stacks for the OpenMediaVault box at `192.168.8.100`.

One directory per stack. Portainer deploys all of them straight from this
repository — except Portainer itself, which is brought up by hand with plain
`docker compose`, because a failed self-redeploy would take down the UI that
manages everything else. That manual path doubles as the bootstrap.

## Bootstrap

```bash
git clone https://github.com/serhii-myronets/homelab-docker-stack.git
cd homelab-docker-stack
sudo ./bootstrap.sh
```

Creates the shared `backend` network, the data directories under
`/srv/ssd/docker/data/`, verifies the secrets, and starts Portainer. Idempotent.

Secrets are never in git. Create them under `/srv/ssd/docker/secrets/`, mode
`600`, before running:

| File | Contents |
|---|---|
| `portainer/license.env` | `PORTAINER_LICENSE_KEY=...` |
| `cloudflared/auth.env` | Cloudflare tunnel token |
| `nordvpn/user`, `nordvpn/pass` | NordVPN OpenVPN credentials, one value per file |

## Stacks

Portainer stacks, added as **Stacks → Add stack → Repository** against this
repo, reference `refs/heads/main`:

| Stack | Compose path | Relative path volumes | Local filesystem path |
|---|---|---|---|
| `caddy` | `caddy/docker-compose.yaml` | on | `/srv/ssd/docker/gitops/caddy` |
| `torrent` | `torrent/docker-compose.yaml` | on | `/srv/ssd/docker/gitops/torrent` |
| `cloudflared` | `cloudflared/docker-compose.yaml` | off | — |
| `jellyfin` | `jellyfin/docker-compose.yaml` | off | — |

`portainer/` is not one of them — deploy it with `./bootstrap.sh`, or
`docker compose -f portainer/docker-compose.yaml up -d`.

Leave **Additional paths** empty: it takes additional *compose* files and merges
them with `-f`, so a non-YAML file there (a `Caddyfile`, say) fails the deploy
with `top-level object must be a mapping`.

**Relative path volumes** is offered only when a stack is *created*, never when
editing one, and it is required by any stack that bind-mounts a file out of this
repo (`./Caddyfile`, `./qBittorrent.conf`). Without it Portainer resolves the
path inside its own container, where the Docker daemon cannot see it; the daemon
then creates an empty directory there and the mount fails with `ENOTDIR`.

## Routes

Caddy terminates TLS with its own internal CA. `*.home` resolves to this host
via a wildcard record on the router at `192.168.8.1`, so new names need no DNS
work. Grab the root certificate from `ca.home` to make browsers trust them.

| Hostname | Backend |
|---|---|
| `omv.home` | OpenMediaVault UI, host port 81 |
| `jellyfin.home` | `jellyfin:8096` |
| `torrent.home`, `flood.home` | Flood UI, `vpn:3000` |
| `proxmenux.home` | ProxMenux Monitor, `10.1.1.100:8008` |
| `proxmox.home` | Proxmox VE, `https://10.1.1.100:8006` |
| `portainer.home` | `portainer:9000` |
| `ca.home` | Caddy's internal root certificate |

Public hostnames on `serhii.link` go through Cloudflare Tunnel instead. It runs
with `--token-file`, so its ingress rules live in the Cloudflare Zero Trust
dashboard, not in this repo.

## Gotchas

**Editing the Caddyfile needs a container restart.** Bind-mounting a single file
pins its inode, and git replaces files rather than editing them in place, so
*Pull and redeploy* alone leaves the container reading the old content — Compose
does not recreate it because the service definition never changed:

```bash
docker restart caddy
```

**`.home` hostnames need `tls internal`.** Without it Caddy goes to Let's
Encrypt, which rejects `.home` as an invalid TLD, and then retries for 30 days —
risking a rate limit on the account that issues the real `serhii.link`
certificates.

**Flood runs as uid 1001** and ignores `PUID`/`PGID`, so its data directory has
to be owned by `1001:1001` or it cannot write its database. `bootstrap.sh`
handles this.
