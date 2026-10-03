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
| Alerting | Nothing tells anyone when something breaks ([0008](decisions/0008-nothing-tells-anyone-when-something-breaks.md)) | Telegram for Gatus on the router (`router/gatus`, decisions/0036), and healthchecks.io for the router itself |
| Router packages | restic's append-only rest-server on the T7 | The router, by an install script under `router/` as Gatus and the exporter are ([0036](decisions/0036-gatus-on-the-router.md)) |
| Terraform state in R2 | core cannot be rebuilt without state and secrets that live only on the Mac | An S3 backend in `core/01-talos`, its own bucket and token |
| Immich machine learning off controlplane | Its 2-3 GiB spikes may be what controlplane's memory runs out on - Grafana will say | worker-1's CPU through OpenVINO, not its GPU - tested 2026-09-30: correct, about 2.5x slower than controlplane |
| The lab network | Proxmox has been unreachable since the router's reflash | A flat LAN in .30-.49, or VLAN 10 rebuilt with rules that isolate |
| [Home Assistant](https://www.home-assistant.io/installation/) | Lights, sockets, sensors, presence | A trial, on Proxmox or worker-1 |
