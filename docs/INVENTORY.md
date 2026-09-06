# Inventory

What physically exists, as of September 2026. Two machines, one router.

## nas — 192.168.8.100

The boring one. Runs OpenMediaVault on bare metal and is not touched between
changes, which is the point of it.

| | |
|---|---|
| CPU | Intel Celeron J4125, 4 cores @ 2.0 GHz |
| RAM | 7.6 GB |
| OS | OpenMediaVault on Debian 13, `openmediavault` |
| Docker | 29.8.0, compose v5.5.1 |

| Disk | | |
|---|---|---|
| `sdb` | M.2 SSD 128 GB | system: `/` (110 G, 9 G used), `/boot/efi`, 6 G swap |
| `sda` | ORICO 1.9 TB SATA SSD | data, ext4, 1.7 T used, ~100 G free |

`sda` mounts at `/srv/dev-disk-by-uuid-925787e7-…`, symlinked to `/srv/ssd`,
which is what every compose file refers to. Neither disk is redundant. SMART
monitoring runs against both; alerting is not configured, so failures land in
the journal rather than an inbox.

**Services** — five stacks, all defined in this repository: Caddy,
Cloudflared, Jellyfin, Portainer, and `torrent` (Gluetun + qBittorrent +
Flood).

**Shares** — SMB exports `samba/torrents` (1.7 T, also mounted into Jellyfin
read-only and qBittorrent read-write) and `samba/scan` (110 M).

## proxmox — 10.1.1.100

The laboratory. Clusters get built and destroyed here through Terraform, so
nothing that needs to stay up lives on it.

| | |
|---|---|
| CPU | Intel Core i9-12900HK, 14 cores / 20 threads, up to 5.0 GHz |
| RAM | 62 GB, ~28 GB in use, load average ~2 across 20 threads |
| GPU | Intel Iris Xe (Alder Lake-P GT2) — QuickSync, well ahead of the NAS's UHD 600 |
| Disk | one Samsung 980 PRO 2 TB NVMe, healthy, 7 % wear, ~4 700 hours |
| Storage | `local-lvm` thin pool 1.67 TB at 3 % used; `local` dir 94 GB |
| Version | Proxmox VE 9.2.11 |

Two things worth knowing before any consolidation: the board has a **free SATA
controller** (`00:17.0`, Alder Lake-P AHCI), so the NAS's ORICO disk has
somewhere to go, and **`enp3s0` is a second NIC sitting unused** — a container
could be bridged straight onto `192.168.8.0/24` rather than re-addressed.

No `vzdump` schedule exists, so the guests below have no backups either.

**Guests** — two Kubernetes clusters, nothing else:

| VMID | Name | RAM |
|---|---|---|
| 100–103 | `talos-controlplane-01`, `talos-worker-01…03` | 6 + 16 × 3 GB |
| 111–113 | `control-plane`, `worker01`, `worker02` | 4 GB each |

Allocation adds up to more RAM than the box has, which is fine while actual
use sits near 28 GB, but there is less headroom than the total suggests.

[ProxMenux Monitor](http://10.1.1.100:8008) runs here and answers on
`/api/*` without authentication — that is where the figures above came from.

## Network

| | |
|---|---|
| `192.168.8.0/24` | the NAS and everything else on the LAN |
| `10.1.1.0/24` | Proxmox, on `vmbr0` |
| `192.168.8.1` | router: gateway, DNS, and the route between the two subnets |

The router answers a **wildcard `*.home` → 192.168.8.100**, so any new
internal hostname works without touching DNS. Caddy terminates those with its
own internal CA; `ca.home` serves the root certificate that makes browsers
trust them.

Public names on `serhii.link` arrive through a Cloudflare Tunnel whose ingress
rules live in the Zero Trust dashboard, not in this repository, because
`cloudflared` runs with `--token-file`.

## What is not here

No off-site anything. Both backup repositories sit inside the NAS, so a fire,
a theft or a dead power supply takes the configuration with the data. The
1.7 TB of media has no backup at all and is treated as re-downloadable.
