---
id: 0007
title: The router is configured through its own UI, never over ssh
status: accepted
date: 2026-09-06
tags: [router, glinet, openwrt, drift, vpn, firewall]
hosts: [router]
---

GL.iNet's firmware keeps its own view of the configuration and regenerates uci
sections from it. A change made over ssh can therefore be invisible in the UI,
silently reverted on the next wizard run, or both. The UI is the source of
truth; uci is its output.

The tell is naming. Every forwarding the firmware creates is called
`<src>2<dest>` — `wgserver2wan`, `lan2wgserver`, `wgserver2wgclient1`. An
anonymous `@forwarding[n]` did not come from the firmware and the firmware does
not know it exists.

On 2026-09-06 three changes were made over ssh and all three were reverted the
same day, unused:

| Change | Reverted to |
|---|---|
| `firewall.sambasharewan.enabled='0'` | key removed — rule enabled again |
| `samba4.@samba[0].interface='loopback lan'` | `loopback wan lan` |
| added `@forwarding` wgserver → lan | deleted |

Verified after reverting: 4 SMB rules back in `zone_wan_input`, 15 forwardings,
no anonymous entry.

## What this leaves open

Two real problems, both recorded in `docs/hosts/router.yaml`, both to be fixed
from the GL.iNet UI:

**VPN clients cannot reach the LAN.** There is a `lan → wgserver` forwarding
and no `wgserver → lan`, so dialling in reaches Proxmox and the Talos cluster
but not the NAS: no Samba, no Jellyfin, and `*.home` resolves to an address
nothing can route to. The peers themselves are already right — `allowed_ips`
covers `192.168.8.0/24` and `10.1.1.0/24`, `dns` is `192.168.8.1`. Only the
router's forwarding table is asymmetric.

**Samba is served on the WAN address.** `firewall.sambasharewan` accepts
137/138/139/445 from the wan zone, `samba4` binds `loopback wan lan`, and a USB
disk is mounted at `/tmp/mountd/disk1_part1`. That share answers on
`50.38.32.155`. This is the more urgent of the two, and it is deliberately left
in place rather than fixed out of band.

## Consequence

Router facts are gathered read-only and written to `docs/hosts/router.yaml`.
Fixes are described there as UI steps for a human, never applied.
