# homelab

A small home Kubernetes cluster, run entirely from this repository: two
low-power machines on [Talos Linux](https://www.talos.dev/), reconciled by
[Flux](https://fluxcd.io/), with every volume that matters backed up to
Cloudflare R2 and able to restore itself onto an empty cluster.

It is one person's house, not a template - but most of it is ordinary
enough to lift into your own setup, and `docs/` records why each piece is
the way it is and what went wrong getting there.

## Hardware

| Machine | Role | |
|---|---|---|
| Beelink ME Pro, Intel N95, 12 GB | `controlplane`: runs nearly everything | 500 GB NVMe for application data, 2x 10 TB HDDs for media and photos |
| Intel Celeron J4125, 8 GB | `worker-1`: monitoring, the dashboard, a second copy of the photos | 2 TB SATA SSD |
| GL.iNet Flint 2 | the router: DNS, DHCP, WireGuard - and the status page | configured by hand, never from here |

Machines are named for their role. A Proxmox lab appears in the history and
the docs; it is not part of what runs.

## Stack

| | |
|---|---|
| OS and cluster | Talos Linux, configured with Terraform ([`core/01-talos`](core/01-talos)) |
| Network | Cilium - kube-proxy replacement, Gateway API, L2 announcements |
| GitOps | Flux, through the Flux Operator ([`core/03-gitops`](core/03-gitops)) |
| Secrets | External Secrets from Infisical; nothing secret is in Git |
| Storage | OpenEBS LVM LocalPV on thin pools; Talos user volumes for the HDDs |
| Backups | VolSync and restic to R2, nightly; etcd snapshots; the router's own backup |
| Certificates and names | cert-manager with a home CA for `*.home`, Cloudflare Tunnel and Access for the few public names |
| Monitoring | VictoriaMetrics, Grafana, Gatus on the router, Homepage at `dash.home` |
| Updates | Renovate in GitHub Actions on the run's own token |

Services: Immich, Jellyfin, Sonarr, Radarr, Prowlarr and Seerr, qBittorrent
behind gluetun, Sure, Vaultwarden, Samba.

## Ideas worth taking

- **A volume that restores itself.** One kustomize component,
  [`backed-up-volume`](core/03-gitops/components/backed-up-volume), gives a
  service a claim that VolSync backs up to R2 and that fills itself from R2
  when the cluster is rebuilt empty. A full rebuild brought every service
  back in about two minutes.
- **Facts as YAML, checked against the machines.** [`docs/hosts/`](docs/hosts)
  describes each machine as it is; [`docs/traps.yaml`](docs/traps.yaml)
  holds each failure met so far - symptom, cause, how to tell, the fix -
  and [`docs/decisions/`](docs/decisions) each choice with what was rejected.
- **The status page lives outside the cluster.** Gatus runs on the router as
  a static binary, pushed by [`router/gatus/install.sh`](router/gatus), so it
  still reports when the cluster is down.
- **HDDs as Talos user volumes**, reached through static PVs, so a reinstall
  keeps the data on them.

## Layout

| Path | |
|---|---|
| [`core/01-talos/`](core/01-talos) | Terraform for both nodes; state in R2 |
| [`core/02-platform/`](core/02-platform) | Helmfile bootstrap: Cilium, External Secrets, the Flux Operator |
| [`core/03-gitops/`](core/03-gitops) | everything Flux reconciles |
| [`router/`](router) | what is installed on the router, each with its own `install.sh` |
| [`docs/`](docs) | facts, decisions, traps; start at [`docs/index.yaml`](docs/index.yaml) |
| [`archive/`](archive) | setups switched off but kept whole, with how to bring each back |

[`core/README.md`](core/README.md) is the operational manual.
[`AGENTS.md`](AGENTS.md) is the briefing for coding agents, and a short
summary of the rules this repository keeps.

## Adapting it

Nothing here runs unchanged elsewhere. The parts that are this house's own:
the `192.168.8.0/24` addresses, the disk serials and IDs in the Talos
patches, the `serhii.link` domain and its Cloudflare account, the Infisical
project behind every `ExternalSecret`, and the R2 bucket. Read
[`docs/traps.yaml`](docs/traps.yaml) before copying anything that touches
storage or the Gateway.

## License

[MIT](LICENSE).
