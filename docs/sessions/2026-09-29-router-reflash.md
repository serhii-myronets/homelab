---
date: 2026-09-29
title: A firmware update bricks the router and the reflash wipes it
tags: [router, glinet, beelink, talos, dhcp, dns, wireguard, vlan, traps]
hosts: [router, beelink]
---

# A firmware update bricks the router and the reflash wipes it

On 2026-09-28 a GL.iNet firmware update left the Flint 2 unbootable. The
owner recovered it by flashing 4.11.0, which kept nothing. Which version
bricked it was not recorded.

## What broke

The router still answered on 192.168.8.1 and the internet worked. Everything
that leaned on its settings did not: `*.home` stopped resolving, Proxmox
(10.1.1.100) was unreachable with VLAN 10 gone, and the Beelink came back on
192.168.8.238 from the pool, because its reservation was gone. The cluster
itself was healthy on the new address — etcd fine, API up — but everything
pinned to .10 pointed at nothing. ssh to the router refused the key and warned
that the host key had changed.

## Rebuilding

The rebuild was driven by `hosts/router.yaml`, the only record that survived,
and done by the owner through the UI; nothing was changed over ssh.

The first advice sent reservations to LuCI. That was wrong for 4.x: GL.iNet's
own UI has them, under Network → LAN and from the client list.

After the reservation was added, the Beelink restarted its network at 06:10
UTC and was still handed .238. Its Talos log showed a clean REQUEST and ACK
for .238, so the router's DHCP server was not yet using the reservation — had
it been, it would have refused .238. Some time later the node was on .10
without anything else being done; why the reservation took effect late was
not established without access to the router.

The owner then asked whether the address could live in Talos instead. It now
does: `patches/network.yaml` gives `br0` a static 192.168.8.10/24, a route
and a resolver, and DHCP is gone from the node (decisions/0028). The change
was checked three ways before it was applied: `talosctl validate --strict`, a
`talosctl apply-config --dry-run` whose diff was the network documents and
nothing else, and `terraform plan`, one in-place update. `terraform console`
was tried first to render the config and returned the value cached in state,
not the one built from the edited patch — it cannot preview a change.
`terraform apply` was refused to the session as a blind apply; the owner ran
it. The node took the config with no reboot.

The AdGuard rewrite was first entered as `191.168.8.15`. `dig @192.168.8.1`
showed it, and a screenshot of the form confirmed it.

`kubectl` failed with "context was not found": `current-context` named
`admin@beelink`, but the only context in `~/.kube/config` is `beelink`.
Switched with `kubectl config use-context beelink`.

flux.home returned 503 once, just after the address change, and 200 on the
next check. 49 pods were dead: 18 in Error and 31 Completed, every one
stopped for a node shutdown since 2026-09-19 and replaced. They were deleted,
leaving 39 running and one finished Job. See traps.yaml.

## Where it stands

Verified read-only once the owner added the ssh key: DDNS back and resolving to
the WAN address, Wi-Fi names back, AdGuard rewrite correct, the WAN open only
to DHCP renew, IGMP and WireGuard. The router serves no Samba; the shares seen
on the LAN are the Beelink's. WireGuard is enabled on 10.1.0.1/24 with no
peers and no LAN access. Not rebuilt: VLAN 10 and the reservations for core
and .110. Tailscale is not used.

## The VLAN question

Firmware 4.11, the owner reports, can now make VLANs in GL.iNet's own UI,
which is where decisions/0007 says such a setting then belongs. Unchecked
here. Advice given, not yet decided:

- Proxmox, as a lab built to be broken, should get a VLAN again, but one that
  isolates: LAN may reach the lab, the lab reaches the internet and the
  router's DHCP and DNS but not the LAN, and no masquerading into it. The old
  VLAN let traffic both ways, so it separated addresses and nothing else.
- The Beelink should stay on the LAN. Moving it changes the node's address,
  every load-balancer IP and the `*.home` rewrite, breaks discovery (DLNA,
  mDNS) across the VLAN boundary and routes every stream through the router,
  to protect a machine the LAN's own clients must reach anyway.

## Loose ends

- A read of the live machine config printed the cluster secret, the
  Kubernetes CA key and the bootstrap token into the session transcript.
  Nothing reached the repository; whether to rotate them is the owner's call.
- The WireGuard subnet is back on 10.1.0.0/24; with no peers yet,
  renumbering it now is free (router.yaml, gaps).
