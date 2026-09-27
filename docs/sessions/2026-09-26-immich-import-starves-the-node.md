---
date: 2026-09-26
title: The first Immich import takes the Gateway down
tags: [beelink, immich, cilium, openebs, resources, memory, talos, infisical, backup, traps]
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
stopped answering.

It was first read as CPU starvation, because none of those pods requested
CPU and their probes were timing out. That was wrong, or at most half of it.
Once the session was allowed to read the node's logs, `talosctl dmesg` showed
Talos's OOM controller sending SIGKILL to whole pod cgroups: 35 times between
02:45 and 02:50 UTC, every one a BestEffort pod - Envoy, the operator and the
two OpenEBS pods. Node memory was exhausted, and pods with no requests at all
are the first victims. See traps.yaml.

Scaling machine learning to zero and suspending its Flux Kustomization was
tried first and refused by the session's permission check, as was reading the
node's logs at that point. The changes went through git:

- Immich's server and machine learning each capped at one core, with every
  Immich probe given five seconds.
- CPU and memory requests on the Cilium agent, Envoy and operator, and on
  every OpenEBS LVM container. This is what ended the outage, though for a
  reason other than the one it was made for: with requests they are no longer
  BestEffort, so the OOM controller passes them over.

Flux applied Immich and OpenEBS. Cilium lives in the Helmfile bootstrap and
was applied by hand; `helmfile diff` before it re-applied the prepare hook,
which is now a trap of its own. The routes came back and have stayed up. Two
VolSync runs that failed while OpenEBS restarted, actual and torrent,
succeeded on their own at 02:53 UTC.

The OOM controller then moved on to Burstable pods and killed the Immich
server twice, at 02:57 and 02:59. The first was misread as the container
reaching its 2 GiB limit, and the limit went to 3 GiB; the pod's own
memory.events had no oom_kill, and the dmesg entry settles it as the node.
At 03:10 the node had 534 MB available of 11708, with 2.3 GB of shared
memory. The `flux` installed from Homebrew's core formula turned out to be
InfluxData's query-language shell, not Flux CD, which lives in the
fluxcd/tap tap.

Left open: the photographs now exist and still have no second copy; the job
concurrency inside Immich's own settings was not lowered; the smart-search
entry for one photo failed while models loaded and needs Jobs, Missing.
