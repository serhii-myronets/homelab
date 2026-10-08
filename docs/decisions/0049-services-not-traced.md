---
id: "0049"
title: The services are not traced; OBI was tried for two days and removed
date: 2026-10-07
status: accepted
tags: [observability, traces, opentelemetry, ebpf, obi]
hosts: [core]
---

# The services are not traced; OBI was tried for two days and removed

Tempo (0048) has one source, Grafana. The services here are other people's
images - Immich, Jellyfin, Vaultwarden, the *arr stack - none of which
sends OTLP or can be made to without rebuilding it. The owner's interest
was the map of who calls whom, and nothing else in the stack needs their
spans. So they stay untraced; Tempo and the collector's OTLP receiver are
kept for whatever is instrumented later.

## What the trial showed

OpenTelemetry eBPF Instrumentation, the instrumentation Grafana gave to
OpenTelemetry as Beyla, ran on core from 2026-10-06 to 2026-10-07 as a
DaemonSet (chart `opentelemetry-ebpf-instrumentation` 0.14.3, OBI v0.14.0;
the manifest is in git history).

- It works. With `context_propagation: headers` it writes `traceparent`
  into plain HTTP calls, and Immich's server calling machine-learning, or
  the library calling Jellyfin and qBittorrent, became one trace across
  both services; no service restarted or failed a request. Without it,
  its default, every service's spans stand alone and the service graph
  holds only users calling services.
- PostgreSQL queries from Immich and Sure produced no spans; Redis and
  Valkey calls did.
- Restricted to the services' namespaces it still attached to every
  process in them: 45 on controlplane, 29 of them s6 supervisors,
  busybox, tini and Samba, which it cannot read.
- Its memory is mostly the kernel's, charged to its cgroup - eBPF maps in
  vmalloc - and so counted against its limit: on 2026-10-07 controlplane
  held 35 MiB in the process, 337 MiB in the kernel and 130 MiB of page
  cache from reading binaries; worker-1, with 4 processes, 25, 204 and 15.
  About 200 MiB a node whatever the traffic.
- Grafana's service graph drew the map, but not as readably as Hubble UI;
  that was the reason it went.

## Rejected

- **Keeping OBI.** Half a gigabyte on controlplane for a map nobody reads.
- **Coroot.** The best-looking automatic maps, one UI for several clusters,
  but ClickHouse beside it - 1-2 GiB more - and a product of its own, off
  the standard stack this one follows.
- **Hubble UI on core.** Draws connections well, but one UI per cluster -
  the owner wants no second address - and enabling it rolls Cilium's
  agents, which took the Gateway down for 71 s the last time (traps.yaml).
- **The OpenTelemetry Operator's auto-instrumentation.** A language SDK
  injected into each pod, only for Java, .NET, Node.js, Python and Go,
  restarting every pod it touches; Jellyfin, Vaultwarden and the *arr
  apps fit it badly or not at all.
- **Context propagation in `tcp` mode**, had OBI stayed. It carries the
  context in a TCP option, which L7 proxies - the Gateway's Envoy - drop.
