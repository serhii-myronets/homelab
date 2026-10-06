---
id: "0044"
title: Scrapes and rules are written in the Prometheus Operator's types; VictoriaMetrics runs them
date: 2026-10-05
status: accepted
tags: [observability, metrics, prometheus-operator, victoriametrics]
hosts: [core]
---

# Scrapes and rules are written in the Prometheus Operator's types; VictoriaMetrics runs them

The second piece of the move toward what the industry runs (0043 was logs).
The owner keeps VictoriaMetrics as the metrics backend. What sets this stack
apart from the common one is not the store but how scrapes and rules are
declared: `VMServiceScrape` and its kin, where nearly every chart and every
team writes `ServiceMonitor`, `PodMonitor`, `PrometheusRule` and
`ScrapeConfig`.

So the Prometheus Operator's CRDs are installed, without the operator, as
the first release of the platform bootstrap (`core/02-platform`), before
Cilium. A monitor lives in the release of what it watches - the chart's own
when it ships one - and the platform's charts are installed by Helmfile
before Flux exists, so the types have to be there from the first apply.
For a day they were a Flux Kustomization of their own that others
depended on; that could not serve Cilium, External Secrets or the Flux
Operator. The VictoriaMetrics operator converts each into its
own kind, which vmagent and vmalert act on; it owns what it converts, so a
monitor Flux prunes takes its scrape with it. Only the kinds it converts are
installed - not `Prometheus`, `Alertmanager`, `PrometheusAgent` or
`ThanosRuler`, which nothing here would act on.

Where a chart ships a monitor it is switched on in that release:
cert-manager, both external-dns releases, OpenEBS's LVM driver. VolSync's
chart ships none, so its `ServiceMonitor` is written beside the release;
the Flux controllers, which no release installs, have the `PodMonitor` of
Flux's own example in `core/03-gitops/apps/system/platform/flux`. The
router is not a cluster resource, and its `ScrapeConfig` stays in
observability. The VictoriaMetrics chart's own scrapes - kubelet,
kube-state-metrics, node-exporter - stay as the chart renders them.
Together these took core from 69k series to 73k on 2026-10-05; the lab
added 81k.

## Rejected

- **kube-prometheus-stack, with VictoriaMetrics as remote storage.** The
  most common shape in companies with many clusters: a full Prometheus in
  each, writing a copy to a central store. Here it would hold a second copy
  of core's metrics and an estimated 0.5-1 GiB more on worker-1, for
  autonomy core already has, its store being local.
- **The Prometheus Operator running a PrometheusAgent in vmagent's place.**
  Agent mode evaluates no rules, so the VictoriaMetrics operator would stay
  for VMSingle, vmalert, vmauth and VictoriaLogs: two operators reading the
  same monitors, for a scraper that does what vmagent does in more memory.
- **The Prometheus Operator in place of VictoriaMetrics'.** It cannot run
  VMSingle, VictoriaLogs or vmauth, and nothing would evaluate
  PrometheusRules without a full Prometheus - which is the first option.
- **VMSingle scraping on its own, without vmagent.** About 50 MiB saved, but
  a restart of the store would stop collection with it, where vmagent
  queues; and it is further from how VictoriaMetrics is run elsewhere.
