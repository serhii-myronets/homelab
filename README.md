# homelab-docker-stack

Docker stacks for the OpenMediaVault box at `192.168.8.100`.
[`docs/`](docs/) holds everything around them — one YAML file per machine, plus
the network, the services and the backups, each fact verified against the live
host. [`docs/index.yaml`](docs/index.yaml) says which file answers which
question. [`docs/decisions/`](docs/decisions/) records why the setup is shaped
the way it is and what is still open;
[`docs/sessions/`](docs/sessions/) records how it got there.

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

## Backup

```bash
sudo ./backup/install.sh
```

Installs restic, initialises a repository at `/var/backups/restic`, and enables
a daily timer. Prints a generated repository password once — save it off the
machine, the backups are unreadable without it.

Each disk holds the backup of what lives on the other one, so losing either
leaves a copy on the survivor:

| Repository | Disk | Holds |
|---|---|---|
| `/var/backups/restic` | `sdb` | `docker/data`, `docker/secrets`, `samba/scan`, `samba/doc` |
| `/srv/ssd/backups/restic` | `sda` | OpenMediaVault's `config.xml` — samba shares, disk mounts, SMART, users, network |

About 220 MB, a few MB a day after that. Jellyfin's cache and metadata are
excluded — 13 GB of artwork and transcodes that a library scan downloads
again, as against the 84 MB of `library.db` that holds watch history, users
and playlists and cannot. Losing the machine loses both repositories; that
needs an off-box target.

Between them, the git repo and these snapshots cover a rebuild end to end.
Portainer's database — and with it the four stack definitions — rides along
inside `docker/data`, so the stacks come back without being recreated by hand.
Not covered: SSH access (run `ssh-copy-id` again) and the installed packages,
though `bootstrap.sh` installs Docker if it is missing.

```bash
export RESTIC_REPOSITORY=/var/backups/restic RESTIC_PASSWORD_FILE=/etc/restic-password
restic snapshots                          # list
restic restore latest --target /tmp/r     # restore everything
restic restore latest --target /tmp/r --include /srv/ssd/samba/scan
```

Containers keep running during a backup, so a snapshot can catch a database
mid-write. Stop the stacks first if you want a guaranteed-consistent one.

## Restore

### The OS was reinstalled, the data disk survived

The disk mount lives in `config.xml`, which lives on that disk, so the first
step is to mount it by hand:

```bash
mkdir /mnt/d && mount /dev/sda1 /mnt/d
apt install restic
restic -r /mnt/d/backups/restic --password-file /mnt/d/backups/password \
  restore latest --target /
reboot
```

OMV reads the restored `config.xml` on boot and brings back the shares, the
disk mount, SMART, the users and the network. Nothing else needs restoring —
`docker/data` and `docker/secrets` are still sitting on the surviving disk.
Then:

```bash
git clone https://github.com/serhii-myronets/homelab-docker-stack.git
cd homelab-docker-stack && sudo ./bootstrap.sh
sudo ./backup/install.sh
```

Portainer comes back knowing all four stacks, since its database is part of
`docker/data`. They still need a **Deploy** each — it does not redeploy stacks
on startup.

### The data disk died

Fit a replacement, mount it at the same path, then restore the other
direction:

```bash
restic -r /var/backups/restic --password-file /etc/restic-password \
  restore latest --target /
chown -R 1001:1001 /srv/ssd/docker/data/torrent/flood
```

`samba/torrents` is not backed up and has to be downloaded again.

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
