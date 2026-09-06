# homelab-docker-stack

Compose definitions for the OpenMediaVault box at `192.168.8.100`.

Everything except Portainer itself is deployed by **Portainer GitOps stacks**
pointed at this repository. Portainer is deliberately left out of that loop — a
failed self-redeploy would take down the UI that manages every other stack — so
it is brought up by hand with plain `docker compose`, which is also the
bootstrap path below.

## Bootstrap (from nothing)

Order matters: the shared network and the secrets have to exist before any
stack will come up.

### 1. Shared network

Every stack joins `backend` as an **external** network, so nothing creates it:

```bash
docker network create backend
```

### 2. Secrets

None of these are in git. Recreate them on the host under
`/srv/ssd/docker/secrets/` (mode `600`):

| Path | Contents |
|---|---|
| `portainer/license.env` | `PORTAINER_LICENSE_KEY=...` (Portainer EE licence) |
| `cloudflared/auth.env` | Cloudflare tunnel token |
| `nordvpn/user`, `nordvpn/pass` | NordVPN OpenVPN credentials, one value per file |

### 3. Data directories

Bind mounts live under `/srv/ssd/docker/data/<service>/`. Create them as needed.
One has a non-obvious owner — Flood runs as uid/gid `1001` and cannot be
remapped with `PUID`/`PGID`:

```bash
mkdir -p /srv/ssd/docker/data/flood/data
chown -R 1001:1001 /srv/ssd/docker/data/flood/data
```

### 4. Portainer

```bash
git clone https://github.com/serhii-myronets/homelab-docker-stack.git
cd homelab-docker-stack
docker compose -f stack/portainer/docker-compose.yaml up -d
```

`restart: unless-stopped` takes care of reboots; nothing else supervises it.
The same command re-applies any change to that file.

> The running container is currently still owned by OpenMediaVault's Docker
> Compose plugin, which generates its own copies under
> `/srv/ssd/docker/compose/portainer/` and marks them "do not edit". While that
> is the case, this repo is the source of truth and the OMV files have to be
> kept in sync by hand — see the header in
> [stack/portainer/docker-compose.yaml](stack/portainer/docker-compose.yaml).

### 5. Everything else, via Portainer

Add each of these as **Stacks → Add stack → Repository**, pointed at this repo,
reference `refs/heads/main`:

| Stack | Compose path | Relative path volumes | Local filesystem path |
|---|---|---|---|
| `caddy` | `stack/caddy/docker-compose.yaml` | on | `/srv/ssd/docker/gitops/caddy` |
| `torrent` | `stack/qbittorrent/docker-compose.yaml` | on | `/srv/ssd/docker/gitops/torrent` |
| `cloudflared` | `stack/cloudflared/docker-compose.yaml` | off | — |
| `jellyfin` | `stack/jellyfin/docker-compose.yaml` | off | — |

Leave **Additional paths** empty. It takes additional *compose* files and merges
them with `-f`, so putting a non-YAML file there (a `Caddyfile`, say) fails the
deploy with `top-level object must be a mapping`.

**Relative path volumes** is only offered when the stack is *created*, and it is
required by any stack that bind-mounts a file out of this repo (`./Caddyfile`).
Without it Portainer resolves the path inside its own container, where the
Docker daemon cannot see it; the daemon then creates an empty directory there
and the mount fails with `ENOTDIR`.

## Gotchas

**Editing the Caddyfile needs a container restart.** Bind-mounting a single file
pins its inode, and git replaces files rather than editing them in place, so a
*Pull and redeploy* alone leaves the container reading the old content — Compose
does not recreate the container because the service definition did not change:

```bash
docker restart caddy
```

**`.home` hostnames need `tls internal`.** `*.home` resolves to this host via a
wildcard record on the router at `192.168.8.1`. Without `tls internal` Caddy
tries to get a public certificate, Let's Encrypt rejects `.home` as an invalid
TLD, and it retries for 30 days — which risks rate-limiting the account used for
the real `serhii.link` certificates.

**The Cloudflare tunnel is not configured here.** It runs with `--token-file`,
so its ingress rules are remotely managed from the Cloudflare Zero Trust
dashboard, not from any file in this repo.

## Services

| Hostname | Backend |
|---|---|
| `omv.home` | OpenMediaVault UI, host port 81 |
| `jellyfin.home` | `jellyfin:8096` |
| `torrent.home`, `flood.home` | Flood UI, `vpn:3000` |
| `proxmenux.home` | ProxMenux Monitor, `10.1.1.100:8008` |
| `proxmox.home` | Proxmox VE, `https://10.1.1.100:8006` |
| `portainer.home` | `portainer:9000` |
| `ca.home` | Caddy's internal root certificate, for trusting the above |
