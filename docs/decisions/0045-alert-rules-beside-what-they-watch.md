---
id: "0045"
title: Alert rules are PrometheusRules beside what they watch, written for what the chart's rules miss
date: 2026-10-05
status: accepted
tags: [observability, alerting, prometheus-operator, victoriametrics]
hosts: [core]
---

# Alert rules are PrometheusRules beside what they watch, written for what the chart's rules miss

The VictoriaMetrics chart brings kube-prometheus's rules: pods crashing or
not ready, volumes filling, nodes short of disk or memory, targets down,
and the stack's own health. What they cannot see is what this cluster runs
on top of Kubernetes. Those rules are written here as `PrometheusRule`s,
each beside the thing it watches - the same rule as for monitors (0044):

| Rules | Watch | Beside |
|---|---|---|
| cert-manager | a certificate near expiry, or not Ready | cert-manager |
| external-secrets | an ExternalSecret no longer syncing | the store's configuration |
| external-dns | a stale sync, repeated errors | both releases |
| lvm | a thin pool at 80% and 90%; a node reporting no volumes | OpenEBS |
| volsync | a source that missed its schedule | VolSync |
| cilium, gateway | unreachable nodes, BPF maps near full, a backend answering 5xx | gateway-system, Cilium's configuration |
| flux | an object not Ready, or suspended for a day | Flux's PodMonitor |
| otel-collector | logs not delivered, queued or refused | the collector |
| cluster | the router's connection table; a CronJob that stops succeeding | observability |

Each expression was evaluated against VMSingle before it was pushed. Only
`LVMVolumesNotReported` fires, for controlplane's thin pool, which the
driver does not report while VolSync's restore snapshots exist
(traps.yaml) - a blind spot worth seeing.

Three of the chart's rules are off. `KubeCPUOvercommit` and
`KubeMemoryOvercommit` ask whether the cluster could lose its largest node
and still place every pod; with two nodes, the HDDs and the GPU on one and
7.6 GB on the other, it never could, so they fired for good. `count:up0` records nothing while
every target is up, which kept `RecordingRulesNoData` firing.

Nothing is delivered yet: alerts show in vmalert, Alertmanager and Grafana.
Where they go is 0008.

## Rejected

- **All rules in one file under observability.** One place to read them,
  but a component's alerts would not move, or go, with the component.
- **The upstream mixins whole** (cert-manager-mixin, and the like). Most of
  their alerts repeat what the chart's rules already cover - target down,
  pod restarts - and the rest are a few lines each.
