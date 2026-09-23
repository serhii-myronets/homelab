---
title: Services to consider next
date: 2026-09-20
tags: [ideas, services, backlog, homelab]
---

# Services to consider next

Ideas, not commitments. What is deployed is in
[hosts/beelink.yaml](hosts/beelink.yaml).

| Service | Why try it | Where |
|---|---|---|
| [Home Assistant](https://www.home-assistant.io/installation/) | Lights, sockets, sensors; presence and event-driven routines. | A Proxmox VM, for a trial |
| [NetBird](https://docs.netbird.io/about-netbird/how-netbird-works) | A private WireGuard mesh across laptops, phones, servers and a VPS. | Proxmox lab project |

Nothing hosted on the Beelink can report that the Beelink is down, which is
the open half of
[decision 0008](decisions/0008-nothing-tells-anyone-when-something-breaks.md).

Settled since this list was written: Immich was built on 2026-09-20, with
its database backed up and its originals deliberately not, yet; Paperless-ngx
was built on 2026-09-22, originals included in the hourly copy to R2, on a
fresh database rather than the empty one archived for it; the *arr stack was chosen and built;
Homepage and Pulse stopped with the rest of core's Docker services; Actual
Budget was built on 2026-09-22 with its data copied to R2 hourly, from a fresh
data directory.
