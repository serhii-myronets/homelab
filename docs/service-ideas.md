---
title: What to build next
date: 2026-09-30
tags: [ideas, services, backlog, homelab]
---

# What to build next

Ideas and planned work, not commitments; what runs is in
[hosts/core.yaml](hosts/core.yaml). Roughly in order of what it protects.

| What | Why | Where |
|---|---|---|
| A second copy of Immich's originals | The only irreplaceable data here has no copy ([backups.yaml](backups.yaml)) | R2, and an append-only copy on the router's T7 |
| Alerting | Nothing tells anyone when something breaks ([0008](decisions/0008-nothing-tells-anyone-when-something-breaks.md)) | Telegram, healthchecks.io, a watcher on the router |
| Router packages | restic's append-only rest-server on the T7, node-exporter, the watcher above | The router, installed through its Plug-ins page; needs a narrow exception to [0007](decisions/0007-router-config-is-not-ours-to-edit.md) for their config files |
| Terraform state in R2 | core cannot be rebuilt without state and secrets that live only on the Mac | An S3 backend in `core/01-talos`, its own bucket and token |
| Metrics and logs back | The VictoriaMetrics stack in `archive/observability` ran twice and worked | worker-1; its archive README lists what that takes |
| Immich machine learning off controlplane | Its 2-3 GiB spikes are what the controlplane's memory runs out on | worker-1's UHD 600, if the no-AVX Celeron runs it - try beside the current one first |
| The lab network | Proxmox has been unreachable since the router's reflash | A flat LAN in .30-.49, or VLAN 10 rebuilt with rules that isolate |
| [Home Assistant](https://www.home-assistant.io/installation/) | Lights, sockets, sensors, presence | A trial, on Proxmox or worker-1 |
