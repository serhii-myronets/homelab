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

## How the two problems were then fixed

Both were fixed the same day, by the owner, through a UI — which is the point.

**Samba on the WAN address** was closed in GL.iNet's own interface. The rule
`firewall.sambasharewan` now targets DROP instead of ACCEPT and `samba4` binds
`loopback lan`. Verified: the eight matching rules in `zone_wan_input` are all
DROP, and the only ports still accepted from the WAN are DHCP renew, IGMP and
WireGuard's 51820.

**VPN clients could not reach the LAN** because a `lan → wgserver` forwarding
existed with no `wgserver → lan`. This one has no GL.iNet toggle at all, which
changes the calculation: there is no vendor state for it to drift *from*, so
LuCI — OpenWrt's own configuration UI, shipped in this firmware — is the right
place, and a rule created there is not out-of-band. It was added as
`wgserver2lan`, following the `<src>2<dest>` names the firmware itself uses, so
it reads as one of the set rather than as something foreign.

The distinction worth carrying forward: **a setting the vendor UI exposes must
be changed there; one it does not expose belongs to LuCI.** Neither belongs to
`uci set` over ssh, because that leaves no trace in either interface.

## Consequence

Router facts are gathered read-only and written to `docs/hosts/router.yaml`.
Fixes are described there as UI steps for a human, never applied.
