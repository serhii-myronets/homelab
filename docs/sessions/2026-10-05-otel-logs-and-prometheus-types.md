---
date: 2026-10-05
title: Core's logs move to the OpenTelemetry Collector, its scrapes to the Prometheus Operator's types
tags: [observability, logs, opentelemetry, victorialogs, metrics, prometheus-operator]
hosts: [core]
---

# Core's logs move to the OpenTelemetry Collector, its scrapes to the Prometheus Operator's types

The owner wants the observability stack closer to what the industry runs,
one piece at a time, keeping VictoriaMetrics and VictoriaLogs as the stores.
Logs came first (0043), then how scrapes are declared (0044).

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

## Metrics: the Prometheus Operator's types

The owner weighed the Prometheus Operator itself and settled on its types
alone (0044): the CRDs, converted by the VictoriaMetrics operator. Most of
the session went into telling apart what Prometheus is - one process that
discovers, scrapes, stores and evaluates - from what this stack splits
across vmagent, VMSingle and vmalert, and why kube-prometheus-stack with
VictoriaMetrics as remote storage is the other common shape.

The router's scrape became a ScrapeConfig and VolSync's a ServiceMonitor
beside VolSync; both converted and are scraped. The converter dropped the
ScrapeConfig's jobName, which blanked Homepage's router widgets until a
relabeling put job="router" back (traps.yaml).

## Next

- The monitors charts ship, one at a time with an eye on the series count:
  cert-manager, external-secrets, external-dns, OpenEBS, Flux, Cilium -
  the last two and external-secrets through Helmfile, applied by hand -
  and a PodMonitor for the collector's own metrics on :8888.
- The lab, paused for now: its vlagent still writes `cluster=lab` through
  ingest.home. It moves to the same collector, with
  `/insert/opentelemetry/v1/logs` added to the `lab` VMUser in ingest.yaml.
- Kubernetes events and Talos's own service logs, both through the
  collector.

Still open from before:
- Whether the Proxmox console's websocket passes through the Gateway on
  proxmox.home; untested.
- Immich's originals outside the house - R2.
- Alerting (0008): a Telegram bot and a healthchecks.io account, then
  Gatus's alerting block and its heartbeat.
