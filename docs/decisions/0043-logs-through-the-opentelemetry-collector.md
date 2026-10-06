---
id: "0043"
title: The OpenTelemetry Collector reads the logs; VictoriaLogs keeps them
date: 2026-10-05
status: accepted
tags: [observability, logs, opentelemetry, victorialogs]
hosts: [core]
---

# The OpenTelemetry Collector reads the logs; VictoriaLogs keeps them

The owner asked for an observability stack closer to what the industry runs,
taken one piece at a time, with VictoriaMetrics and VictoriaLogs kept as the
stores. For logs the store is not where a standard exists: Elasticsearch,
Loki, ClickHouse-based stores and VictoriaLogs all hold a real share. The
collector and its protocol are, and the field there is converging on the
OpenTelemetry Collector and OTLP.

So core's pod logs are read by the collector's k8s distribution, a DaemonSet
(`core/03-gitops/apps/system/observability/app/otel-collector.yaml`), and
written to VictoriaLogs over OTLP. Fields follow the OpenTelemetry semantic
conventions - `k8s.cluster.name`, `k8s.namespace.name`, `k8s.pod.name`,
`k8s.deployment.name`, `severity_text` - where vlagent wrote
`kubernetes.pod_namespace` and a `cluster` field. Nothing queried the old
names. The same collector is where traces will come in, over the same
protocol, when something sends them.

vlagent was retired on core on 2026-10-05, after fifteen minutes side by
side gave the same lines per container. The lab's vlagent still writes
through `ingest.home` (0040) until the lab moves too; until then core's logs
are found by `k8s.cluster.name` and the lab's by `cluster`.

## What it costs

Measured on 2026-10-05: 12m CPU on controlplane and 23m on worker-1's
Celeron, about 50 MiB each, where vlagent held 4-5m and 18-28 MiB. That is
after polling files once a second instead of the default 200ms, which had
cost worker-1 76m.

## Rejected

- **Keeping vlagent.** The cheapest by a factor of four, and good at its
  job, but an agent and a protocol known only inside VictoriaMetrics' own
  stack, and it carries no traces.
- **Fluent Bit.** The most widely deployed and lighter than the collector,
  but a log forwarder first; traces would need a second agent.
- **Grafana Alloy.** Grafana's distribution of the collector, configured in
  its own language. The upstream collector is the standard it is built on.
- **Vector.** The strongest at transforming logs, which nothing here needs.
- **Loki as the store.** No more of a standard than VictoriaLogs, and the
  move would cost the month already kept. VictoriaLogs takes OTLP, so the
  store can still be changed without touching what collects.
