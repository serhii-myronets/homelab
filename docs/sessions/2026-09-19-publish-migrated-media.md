---
date: 2026-09-19
title: Publish the migrated media services through the Beelink tunnel
tags: [beelink, cloudflare, cloudflared, external-dns, jellyfin, torrent]
---

The owner asked for the services previously available through the core tunnel
to come back on `serhii.link`. Jellyfin, qBittorrent and Flood were already
healthy on the Beelink, so their Gateway routes gained the public names
`jellyfin.serhii.link`, `qbittorrent.serhii.link` and `torrent.serhii.link`.
Flood keeps its existing `flood.serhii.link` alias.

Argo applied all three route updates and Cilium accepted their new
generations. The owner removed the old Cloudflare DNS records. On its next
reconciliation external-dns created fresh proxied CNAME records, each pointing
at the locally managed Beelink tunnel. Cloudflare Access returned its login
redirect for all four names.

The old tunnel's other names still need separate work: Homepage and Portainer
need Kubernetes workloads, while OMV, Proxmox and ProxMenux need deliberate
Gateway backends to their existing hosts.
