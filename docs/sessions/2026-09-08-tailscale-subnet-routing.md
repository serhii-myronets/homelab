---
date: 2026-09-08
title: Tailscale routing for LAN and the Proxmox VLAN
tags: [tailscale, router, proxmox, vpn, dns]
hosts: [router, proxmox]
---

Enabled Flint 2's native Tailscale integration for `192.168.8.0/24` and
installed Tailscale natively on Proxmox to advertise `10.1.1.0/24`. The
Proxmox installer lives under `tools/` because the host is not deployed by
Portainer. It enables forwarding, leaves Proxmox DNS unchanged and supports
interactive or environment-supplied authentication without storing a key.

Approving the Proxmox route initially made Proxmox go offline. Flint accepted
the advertised route and installed `10.1.1.0/24 dev tailscale0` in table 52,
overriding its directly attached VLAN for replies. Removing approval restored
connectivity; setting `accept-routes=false` on Flint allowed the route to be
approved without the loop. The failure is recorded in
[traps](../traps.yaml).

Verified from the Mac over Tailscale: `10.1.1.100:8006` reached the Proxmox API,
`homepage.home` resolved through split DNS at `192.168.8.1` to
`192.168.8.100`, and Caddy returned HTTP 200 with normal certificate
validation. Exit nodes are not used.
