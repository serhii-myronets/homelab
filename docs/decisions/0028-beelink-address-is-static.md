---
id: "0028"
title: The Beelink's address is set in Talos, not reserved on the router
date: 2026-09-29
status: accepted
tags: [beelink, talos, network, dhcp, router]
---

# The Beelink's address is set in Talos, not reserved on the router

Until now `br0` took its address by DHCP and the router's reservation held it
at 192.168.8.10. On 2026-09-28 a firmware update left the router unbootable;
flashing it again wiped every setting, the reservation included, and the node
came back on 192.168.8.238. Everything pinned to .10 went with it: the Talos
and Kubernetes endpoints, `cluster_endpoint` in `core-talos/01-talos/main.tf`
and the certificate the API server was issued for.

The address now lives in `core-talos/01-talos/patches/network.yaml`: a static
192.168.8.10/24 on `br0`, a default route through 192.168.8.1 and that router
as the resolver. A router reset can no longer move the node. The hostname was
never DHCP's to give — `HostnameConfig` is `auto: stable` — so it does not
change.

Keeping DHCP and trusting the reservation was the alternative, and it keeps
every address in one table on the router. It was rejected because that table
is the part of the network most likely to be lost, and it is the one thing
here that is not in this repository. The reservation stays on the router
anyway, so the router's client list names the machine; .10 is outside the
DHCP pool, so nothing else can be leased it.

The cost: if the LAN is ever renumbered or the gateway moves, this file has
to change with it.
