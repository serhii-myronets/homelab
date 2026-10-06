---
id: "0048"
title: Traces go through the collector to Tempo; Grafana's OSS charts come from grafana-community
date: 2026-10-06
status: accepted
tags: [observability, traces, tempo, opentelemetry, grafana, helm]
hosts: [core]
---

# Traces go through the collector to Tempo; Grafana's OSS charts come from grafana-community

With metrics in VictoriaMetrics and logs in Loki, traces were the signal
missing. Tempo keeps them (`core/03-gitops/apps/system/observability/app/tempo.yaml`):
Tempo 3.1 in one process on worker-1, a week kept on a 10 GiB volume.

The path is the standard one. An application sends OTLP to
`otel-collector.observability.svc` (4317 gRPC, 4318 HTTP), a Service whose
traffic stays on the sender's node, so the collector there recognises the
pod by its address and adds its Kubernetes names, as it does for logs; it
forwards to Tempo. Nothing is opened on the hosts' ports.

Tempo's metrics generator turns the spans into request, error and duration
series per service and into the calls between services, written to
VMSingle with `cluster=core` - what Grafana's service graph reads. In
Grafana a span links to its pod's logs in Loki.

Nothing in the cluster sent traces before. Grafana itself is the first
source, tracing every one of its own requests. Others come as they are
instrumented; the collector is where they point.

## The charts' new home

Grafana moved its open-source Helm charts to `grafana-community` in March
2026; the Loki chart left in `grafana/helm-charts` is maintained for
Grafana Enterprise Logs, and Tempo's there stopped at 2.9. Both Loki and
Tempo now come from `grafana-community` - Loki moving from chart 7.3.0 to
18.13.8 and from 3.6 to 3.7, with the same StatefulSet and volume.

## Rejected

- **Tempo's Jaeger and Zipkin receivers off.** The chart's Service template
  cannot render without the Jaeger ones; they listen and nothing uses them.
- **Applications sending straight to Tempo.** It would skip the
  collector's Kubernetes attributes and its queue, and tie every
  application to the store.
