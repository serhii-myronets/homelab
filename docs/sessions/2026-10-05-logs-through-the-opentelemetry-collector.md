---
date: 2026-10-05
title: Core's logs move from vlagent to the OpenTelemetry Collector
tags: [observability, logs, opentelemetry, victorialogs]
hosts: [core]
---

# Core's logs move from vlagent to the OpenTelemetry Collector

The owner wants the observability stack closer to what the industry runs,
one piece at a time, keeping VictoriaMetrics and VictoriaLogs as the stores.
Logs came first (0043).

## The collector

A DaemonSet of the collector's k8s distribution reads /var/log/pods on both
nodes and writes to VictoriaLogs over OTLP. It ran beside vlagent first.
Three things were found on the way, each fixed in otel-collector.yaml:

- The apiserver's lines had no node - k8sattributes cannot match static
  pods (traps.yaml, k8sattributes-misses-static-pods).
- Polling files every 200ms held 76m of worker-1's CPU for almost no logs;
  once a second brought it to 23m.
- Prowlarr's blank lines were stored as VictoriaLogs' "missing _msg field";
  they are dropped now, as vlagent did.

A comparison over fifteen minutes then gave the same lines per container
from both, no duplicates, and vlagent was removed from core's stack. The
collector skips its own logs, as the chart does by default; vlagent had
read them.

The configuration was checked before each push with the contrib binary of
the same version, running the rendered config on sample containerd lines.

## Next

- The lab: its vlagent still writes `cluster=lab` through ingest.home. It
  moves to the same collector, with `/insert/opentelemetry/v1/logs` added to
  the `lab` VMUser in ingest.yaml.
- Metrics, the next piece: the Prometheus Operator's CRDs, ServiceMonitors
  in place of VMServiceScrapes, and the charts' own monitors switched on.
  The collector's own metrics on :8888 are not scraped until then.
- Kubernetes events and Talos's own service logs, both through the
  collector.

Still open from before:
- Whether the Proxmox console's websocket passes through the Gateway on
  proxmox.home; untested.
- Immich's originals outside the house - R2.
- Alerting (0008): a Telegram bot and a healthchecks.io account, then
  Gatus's alerting block and its heartbeat.
