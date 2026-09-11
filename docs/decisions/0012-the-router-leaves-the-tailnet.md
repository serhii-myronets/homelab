---
id: "0012"
title: The router leaves the tailnet; core and Proxmox advertise the subnets
date: 2026-09-10
status: proposed
tags: [tailscale, router, glinet, vpn, subnet-routing]
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

Four alternatives were considered. Installing Tailscale on the lab guests
avoids subnet routing altogether, but they are Talos: no shell and no package
manager, so it means a system extension and an image rebuild per node.
Having Flint advertise 10.1.1.0/24 as well as the LAN keeps one subnet router
and no conflict, but `--reset` discards any advertisement set outside
GL.iNet's own UI, so it would survive until the next reboot. Re-enabling
WireGuard as the path to the lab was rejected by the owner, who disabled it
on purpose so two tunnels would not fight over the same routes; it also pins
a DHCP WAN address that has already moved once, and its client subnet
overlaps both the VPN and the lab (see traps). Using Proxmox as a jump host
costs nothing and works today, and is the fallback if this is not done — but
every guest is then two hops away.

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
