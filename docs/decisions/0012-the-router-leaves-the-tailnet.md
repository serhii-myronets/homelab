---
id: "0012"
title: The router leaves the tailnet; core and Proxmox advertise the subnets
date: 2026-09-10
status: proposed
tags: [tailscale, router, glinet, vpn, subnet-routing, zerotier, dns]
hosts: [router, core, proxmox]
---

A Tailscale subnet router must not accept a route for a subnet it is already
attached to: the route lands in table 52 and wins over the physical
interface, so replies leave through the tunnel and the subnet goes dark.
Flint is attached to both of ours — `br-lan.1` carries 192.168.8.0/24 and
`br-lan.10` carries 10.1.1.0/24.

Flint cannot be told not to accept them. `/usr/bin/gl_tailscale:331` runs
`tailscale up --reset --accept-routes` every time the service starts, so
`--reset` discards whatever was set by hand and `--accept-routes` puts
`RouteAll` back to true. Editing that script is what
[0007](0007-router-config-is-not-ours-to-edit.md) forbids, and a firmware
upgrade would revert it anyway. This is not a setting that drifted; it is
the integration working as designed.

So while Flint is a node in the tailnet, neither subnet route can be
approved, and withholding approval — which is where 2026-09-10 left things —
is a ceiling rather than a fix. The lab is reachable over Tailscale only as
far as the Proxmox host's own address.

The decision is to take Flint out of the tailnet and move the job to the two
machines that can hold it: core advertises 192.168.8.0/24 and Proxmox
advertises 10.1.1.0/24, both approved. Neither is a GL.iNet appliance, both
run Tailscale from a package under systemd, and nothing resets their
preferences on boot. AdGuard and the `home -> 192.168.8.1` split-DNS route
are unaffected — the router keeps serving DNS on the LAN, it simply stops
being a tailnet node.

Five alternatives were considered. Installing Tailscale on the lab guests
avoids subnet routing altogether, but they are Talos: no shell and no package
manager, so it means a system extension and an image rebuild per node.
Having Flint advertise 10.1.1.0/24 as well as the LAN keeps one subnet router
and no conflict, and is what the hardware is for — but the firmware cannot
express it. `gl_tailscale` builds its advertised list from a single
`uci get network.lan.ipaddr`: five WAN interfaces are enumerated, the LAN
side is one lookup, and there is no option for a second route. The lab is
`homelab` on `br-lan.10`, an interface made in LuCI because the GL.iNet UI
does not do arbitrary wired VLANs, so the integration has no concept that
the network exists. Setting it by hand does not survive either, since
`--reset` runs on boot and on network events alike, which would drop the
advertisement mid-session rather than only at reboot. Re-enabling
WireGuard as the path to the lab was rejected by the owner, who disabled it
on purpose so two tunnels would not fight over the same routes; it also pins
a DHCP WAN address that has already moved once, and its client subnet
overlaps both the VPN and the lab (see traps). Using Proxmox as a jump host
costs nothing and works today, and is the fallback if this is not done — but
every guest is then two hops away.

The fifth was ZeroTier, which the firmware already carries at 1.14.1 and
leaves disabled. It does not inherit this trap: `/etc/init.d/zerotier` is the
stock OpenWrt script, its whole launch is `procd_set_param command $PROG
$args $path` with `$args` holding at most a port, and it symlinks a
`local_conf` of one's own — so `allowManaged` and its whitelist are reachable
and nothing rewrites them at boot. It fails on DNS instead. Reaching `*.home`
from outside is a requirement, not a nicety, and ZeroTier has no equivalent
of the split-DNS route below. It would also need `zerotier.gl.local_conf`
set, which uci does not carry and the GL.iNet UI does not offer, so
configuring it at all would mean the `uci set` that
[0007](0007-router-config-is-not-ours-to-edit.md) forbids.

Split DNS survives this untouched, which is the obvious thing to fear and
worth stating plainly. The `home -> 192.168.8.1` route is pushed by the
coordination server to every node, not configured on the router: Proxmox,
which is not the router, receives it identically. Nothing about it depends on
who advertises a subnet. All it needs is for 192.168.8.1 to stay reachable
from the tailnet, which is exactly what core advertising 192.168.8.0/24
provides, so `*.home` keeps resolving from outside as it does today.

The cost is that remote access moves off the machine that is always up and
onto two that are not. The power cut on 2026-09-10 is the case in point: the
router came back by itself and core did not. Two things blunt it. Proxmox
stays an independent foothold, reachable at its own tailnet address whether
or not core is running, so being locked out entirely takes both machines
down at once. And core's BIOS should be set to restore on AC power loss,
which removes the cause rather than the symptom.

One loose end follows the change: the `tailscale0 -> lan` and
`tailscale0 -> homelabzone` forwardings on the router become dead
configuration, since nothing will arrive on that interface any more.

Not implemented. The installer under `tools/` covers one host and one CIDR
today and would be generalised to both.
