---
id: "0034"
title: satellite becomes a worker in core rather than a cluster of its own
date: 2026-09-30
status: accepted
tags: [satellite, core, talos, kubernetes, observability, memory]
hosts: [satellite, core]
supersedes: ["0032"]
---

# satellite becomes a worker in core rather than a cluster of its own

For two days satellite ran as its own Talos cluster (0032) - built, working,
and holding about 1.9 GiB of its 7.6 GB for its own platform before any
workload: kube-apiserver alone 1.1 GiB, then Flux, cert-manager, External
Secrets, external-dns, cloudflared. Around it grew the glue that joining two
clusters takes: core's Infisical identity shared, a token for core in
satellite's Headlamp, two external-dns owners, a Cloudflare tunnel each, an
intermediate of home-ca (0033), and remote_write between them still to come.

It rejoins core as a worker at 192.168.8.11, in core's address block. As a
worker it holds about 0.4 GiB for kubelet, the Cilium agent and the node's
exporters, and the rest goes to what is pinned to it: the metrics and log
stores, Grafana, Alertmanager, and Immich's machine learning if it runs on
this Celeron. One cluster, one Flux tree, one console, one tunnel.

## What was weighed and given up

A separate cluster kept three things this does not:

- **Seeing and managing core while its control plane is down.** Pods on
  satellite keep running without the API server, but nothing can be changed,
  and the Gateway address is not expected to move to it. What must survive
  is the alert, not the console: vmalert, Alertmanager and one CoreDNS
  replica are pinned to satellite, and healthchecks.io watches from outside
  the house for what no machine inside can report.
- **Backup copies out of core's reach.** They go instead to the T7 on the
  router behind restic's append-only rest-server, so a core broken into
  cannot erase them.
- **A canary for upgrades.** The Proxmox lab is what that is for.

Moving observability to a separate cluster on Proxmox was also weighed and
deferred: Proxmox is unreachable until the network is decided, lost power
unsafely 65 times in 115, and is the lab.

## As built

`core/01-talos` carries a worker configuration for satellite from core's own
secrets: the install disk by the tail of its WWID, a br0 bridge over enp1s0
so Cilium's devices, direct routing and L2 announcements name the same
interface on both nodes, the hostname satellite, 8 GiB of swap behind zswap
with EPHEMERAL capped before the install, and dm_thin_pool for the ORICO's
thin pool. The first apply goes to satellite's maintenance address after
`talosctl reset`.

## What followed, the same day

core itself was rebuilt so that no node kept a generated name: the cluster
became `core`, the Beelink `controlplane` and satellite `worker-1`. The
observability stack went back to the archive rather than onto worker-1 for
now, and satellite's own tree left the repository.
