---
date: 2026-09-26
title: The first Immich import takes the Gateway down
tags: [beelink, immich, cilium, openebs, resources, infisical, backup, traps]
hosts: [beelink, router]
---

# The first Immich import takes the Gateway down

The session began as questions. Cloudflare Secrets Store was weighed as a
replacement for Infisical and ruled out: its values are write-only, readable
only by a Worker binding, and External Secrets has no provider for it; the
free tier's 20 secrets would also be nearly spent by the 18 in use. Infisical
itself was judged adequate, because External Secrets keeps a synced Secret
when the provider is unreachable. The open risk is elsewhere: the R2 restic
password, Sure's Active Record keys and the Infisical machine credential have
no confirmed copy outside Infisical and this laptop.

A 1 TB Samsung T7 was considered as an offline copy of Immich's originals.
The router still carries a guest-writable Samba share named `T7` from the time
that disk answered on the WAN; nothing is plugged in now. Putting it back
online was advised against, since an always-writable copy fails the same way
as the original.

Then a phone began uploading into Immich. At the first look the node sat at
100% CPU and 93% memory, the server at 1.6 of its 2 GiB, and machine learning
failing probes while it downloaded its models. Minutes later cilium-envoy,
cilium-operator and both OpenEBS pods were restarting and every Gateway route
stopped answering. Neither Cilium nor OpenEBS requested any CPU, so under
contention they got the smallest share the kernel gives; their one-second
probes timed out, and the restarts added load. See traps.yaml.

Scaling machine learning to zero and suspending its Flux Kustomization was
tried first and refused by the session's permission check, as was reading the
kernel log through talosctl. The fix went through git instead:

- Immich's server and machine learning each capped at one core, with every
  Immich probe given five seconds, since a throttled pod answers slowly.
- CPU and memory requests on the Cilium agent, Envoy and operator, and on
  every OpenEBS LVM container. Requests only; limits would throttle the
  network and the volume driver.

Flux applied Immich and OpenEBS. Cilium lives in the Helmfile bootstrap and
was applied by hand; `helmfile diff` before it re-applied the prepare hook,
which is now a trap of its own. Within minutes the node fell to about 40% CPU,
every rollout completed, and the routes answered. Two VolSync runs that failed
while OpenEBS restarted, actual and torrent, succeeded on their own at 02:53
UTC. The Immich server restarted twice waiting for Postgres's volume, then
settled.

Left open: the photographs now exist and still have no second copy; the job
concurrency inside Immich's own settings was not lowered; the smart-search
entry for one photo failed while models loaded and needs Jobs, Missing.
