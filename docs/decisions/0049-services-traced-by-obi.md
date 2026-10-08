---
id: "0049"
title: The services are traced from the kernel by OBI, with trace context written into their HTTP calls
date: 2026-10-07
status: accepted
tags: [observability, traces, opentelemetry, ebpf, obi]
hosts: [core]
---

# The services are traced from the kernel by OBI, with trace context written into their HTTP calls

Tempo (0048) had one source, Grafana. The services here are other people's
images - Immich, Jellyfin, Vaultwarden, the *arr stack - none of which
sends OTLP or can be made to without rebuilding it. OpenTelemetry eBPF
Instrumentation (`core/03-gitops/apps/system/observability/app/obi.yaml`),
a DaemonSet, reads their HTTP, gRPC and Redis traffic in the kernel and
writes spans to the collector on its node and RED metrics for the scrape.
It is the instrumentation Grafana gave to OpenTelemetry as Beyla.

It watches the services' namespaces only. Left to its default it traced
the controllers' calls to the API server, and the observability stack's
own traffic made a span for every span stored.

## Linking callers to callees

With context propagation off, OBI's default, each service's spans stood
alone: the service graph showed users calling services and nothing else.
In `headers` mode OBI writes a `traceparent` header into the plain HTTP
requests a traced process sends, and the callee's spans join the caller's
trace. Checked on 2026-10-07 after five minutes: Immich's server calling
machine-learning, the library calling Jellyfin and qBittorrent, each one
trace across both services; no service restarted or failed a request.

What it does not reach:
- Calls in TLS: there is no plaintext to write into. Inside the cluster
  the services talk plain HTTP; TLS ends at the Gateway.
- PostgreSQL. Neither Immich's nor Sure's queries produced a span in the
  first half hour; Redis and Valkey calls did.
- Anything inside a process. A span is a request in or out, not the work
  between; that needs the application's own SDK.

## What it costs

Measured on 2026-10-07: 59m CPU and 462 MiB on controlplane, which carries
most of the traced traffic, 17m and 238 MiB on worker-1. The most expensive
piece of the observability stack per node, and the first to remove if
memory runs short.

## Rejected

- **Context propagation in `tcp` mode.** It carries the context in a TCP
  option, which works below HTTP but is dropped by L7 proxies - the
  Gateway's Envoy - and resets connections on some paths.
- **The OpenTelemetry Operator's auto-instrumentation.** It injects a
  language SDK into each pod, so it gives spans inside the process, but
  only for Java, .NET, Node.js, Python and Go, restarts every pod it
  touches, and depends on each image's runtime. Jellyfin, Vaultwarden and
  the *arr apps fit it badly or not at all.
- **Hubble's flows as traces.** Cilium already sees every connection, but
  a flow is a connection between two pods, not a request with a parent;
  it cannot say which call to Jellyfin a library request made.
- **Grafana Beyla.** The same code under Grafana's name, configured its
  own way; OBI is the upstream it now tracks.
