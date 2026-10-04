---
date: 2026-10-03
title: The lab rebuilt on the LAN, and .home names for both clusters
tags: [proxmox, lab, router, dns, bind, adguard, external-dns, infisical, cloudflare, gateway, traps]
hosts: [proxmox, router, core]
---

# The lab rebuilt on the LAN, and .home names for both clusters

One day. What follows is the story; every fact it touches already lives in
hosts/, network.yaml, traps.yaml or decisions/.

## The lab

Proxmox was reinstalled on the flat LAN at 192.168.8.30, on ZFS with the
VMs' dataset unsynced, and the lab's repository rebuilt around it: Talos and
Kubernetes on core's versions, three control planes and two workers at
.40-.46 with the API at .50, Talos provider 0.12's talos_machine and
talos_cluster, an API token in place of the root password, state in R2.
Talos 1.14's configuration contract turned out to refuse the old v1alpha1
keys beside its new documents, so every patch was rewritten. The state
before all of it, tagged v0.1.0 on the lab's main, got a GitHub release.

The lab keeps its own Argo CD. Its secrets moved out of core's Infisical
project into one of its own, proxmox-lab, read by a machine identity with
access to nothing else - until then the lab had held core's identity
`homelab`, which is an organization admin. It got its own Cloudflare tunnel,
`lab`, and its own external-dns as owner `lab`.

## Names under .home

The owner wanted one .home for both clusters, each name published by the
cluster that serves it. AdGuard was the obvious place and the wrong one:
GL.iNet runs it in a mode that admits only the router's own session
(traps.yaml, glinet-adguard-admits-only-the-router-session). A proxy holding
the router's root password was refused. Taking --glinet off did work - an
install script, a decision, core's external-dns writing 16 names - and was
undone the same evening: AdGuard had left the router's login, two firmware
files were ours to keep patched, and each cluster held a credential that
could rewrite any name in the house. The router went back from its backup,
byte for byte, with the rules and users gone.

What replaced it is BIND from the router's own feed, authoritative for
home. on port 5300, written over RFC 2136 with one TSIG key per cluster
(0039). AdGuard forwards .home to it and its *.home rewrite is gone, so an
unknown name now answers NXDOMAIN rather than core's Gateway. Core's second
external-dns, external-dns-bind, needed its own annotation prefix before it
would publish A records at all (traps.yaml,
external-dns-follows-the-gateway-target-whatever-the-flags). Both of core's
external-dns now own their records as `core`, renamed from `beelink` with a
one-time migration flag, which rewrote every record on every run until it
was taken out again.

proxmox.home began as a static record in the zone and ended as a route:
a socat pod, as gatus.home has, carrying the Gateway's plain HTTP to the
host's own HTTPS, so the host's UI has home-ca's certificate and no port.
Both proxies now live in apps/system/network/proxies, one Kustomization and
one namespace. Every .home name comes from an external-dns now; the zone's
seed holds only its SOA and NS.

Still open:
- The lab's external-dns-bind, owner lab, beside its Cloudflare one.
- Rotate the client secret of the Infisical identity `homelab` - the lab's
  cluster held it until today - and narrow it from organization admin to
  core's project.
- Whether the Proxmox console's websocket passes through the Gateway on
  proxmox.home; untested.
- Immich's originals outside the house - R2.
- Alerting (0008): a Telegram bot and a healthchecks.io account, then
  Gatus's alerting block and its heartbeat.
