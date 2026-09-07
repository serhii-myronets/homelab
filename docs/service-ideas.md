---
title: Services to consider next
date: 2026-09-06
tags: [ideas, services, backlog, homelab]
---

# Services to consider next

Saved from the service shortlist discussed on 2026-09-06. These are ideas,
not deployment commitments. Placement is tentative; check current resources
and upstream requirements before installing. Deployed services are tracked in
[services.yaml](services.yaml).

| Service | Why try it | Tentative placement |
|---|---|---|
| [Paperless-ngx](https://docs.paperless-ngx.com/) | Searchable archive for scans, receipts, warranties and contracts. A useful extension of the existing scanning workflow. | core |
| [Immich](https://immich.app/features) | Personal photo library with mobile uploads, face recognition and search. | Trial on Proxmox; choose permanent storage and host afterwards |
| [Home Assistant](https://www.home-assistant.io/installation/) | Automate lights, sockets and sensors; experiment with presence and event-driven routines. | Dedicated Proxmox VM for a trial |
| [Actual Budget](https://actualbudget.org/) | Personal budgeting and expense planning with local-first data. | core |
| [Uptime Kuma](https://github.com/louislam/uptime-kuma) | Service availability checks, outage history and notifications. | Proxmox, so it can observe core outages |
| [NetBird](https://docs.netbird.io/about-netbird/how-netbird-works) | Experiment with a private WireGuard mesh connecting laptops, phones, servers and a VPS. | Proxmox lab project |
| [Homepage](https://gethomepage.dev/) | One start page for service links and status widgets. Already chosen; configuration is in [core/homepage](../core/homepage/). | core |

Paperless-ngx was the suggested first practical addition; Immich the photo
project with the biggest visible payoff; Home Assistant the hands-on
experimentation option. No next service has been selected yet.

For Immich, plan backups of both originals and the database before importing
important photos; see its [backup guide](https://docs.immich.app/administration/backup-and-restore/).
A service that becomes essential at home should have a stable home independent
of disposable lab experiments. Uptime Kuma on Proxmox would not detect a
whole-home power or internet outage from outside; the existing alerting work
is described in [decision 0008](decisions/0008-nothing-tells-anyone-when-something-breaks.md).
