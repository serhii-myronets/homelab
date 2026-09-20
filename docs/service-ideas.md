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
| [Immich](https://immich.app/features) | Photo library with mobile uploads, face recognition and search. The idea with the biggest visible payoff. | Beelink, once storage for it is decided |
| [Home Assistant](https://www.home-assistant.io/installation/) | Lights, sockets, sensors; presence and event-driven routines. | A Proxmox VM, for a trial |
| [Actual Budget](https://actualbudget.org/) | Budgeting with local-first data. | Beelink |
| [Uptime Kuma](https://github.com/louislam/uptime-kuma) | Availability checks, outage history, notifications. | Not the Beelink - something that watches it has to outlive it |
| [NetBird](https://docs.netbird.io/about-netbird/how-netbird-works) | A private WireGuard mesh across laptops, phones, servers and a VPS. | Proxmox lab project |

Immich needs backups of both the originals and its database planned before
any photo worth keeping goes in; see its
[backup guide](https://docs.immich.app/administration/backup-and-restore/).

Nothing hosted on the Beelink can report that the Beelink is down, which is
the open half of
[decision 0008](decisions/0008-nothing-tells-anyone-when-something-breaks.md).

Settled since this list was written: Paperless-ngx is postponed and its
database archived; the *arr stack was chosen and built; Homepage and Pulse
stopped with the rest of core's Docker services.
