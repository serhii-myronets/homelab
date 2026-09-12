---
date: 2026-09-12
title: Remove Tailscale from Proxmox
tags: [tailscale, proxmox, network]
hosts: [proxmox]
---

The owner requested removal after the router coexistence failures recorded
in traps.yaml. Proposal 0012 was withdrawn instead of moving subnet routing
to core and Proxmox.

Connected directly over LAN, logged out, stopped the daemon and purged the
package. Removed local state/cache, the dedicated APT source/key and the
installer's sysctl file. Runtime forwarding values were left alone to avoid
changing VM networking. No reboot or router changes were made.

A fresh LAN SSH connection succeeded; pveproxy and pulse-agent were active,
tailscale0 was absent, and no Tailscale iptables chains remained. No removal
step failed. Local identity state is not retained; reinstalling requires
authentication again. The admin-console machine record was not deleted.
