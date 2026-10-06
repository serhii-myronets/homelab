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

Then the monitors charts ship, one release at a time: cert-manager,
external-dns, OpenEBS's LVM driver, and a PodMonitor for the Flux
controllers, which no release installs - about 4k series together. The
LVM driver turned out to report no volumes at all on controlplane while
VolSync's restore snapshots of 2026-09-30 exist (traps.yaml); deleting
them is the owner's call, and no upstream issue was filed.

The owner wants each monitor in the release of what it watches. Helmfile
installs Cilium, External Secrets and the Flux Operator before Flux
exists, so the CRDs moved from a Flux Kustomization into Helmfile, as its
first release under the same name: Flux uninstalled its release, the CRDs
stayed by their keep policy, and `helmfile apply` adopted them without
recreating them.

Last, the Helmfile releases: Cilium's agent (its metrics switched on),
operator and Envoy, External Secrets and the Flux Operator, each from its
chart, and the collector's PodMonitor from its own. A server-side dry run
showed Cilium's CA would be kept, which helm-diff cannot see. Envoy was
cut to a keep-list, 7,237 series per node to about 300. Core ended at 78k
series.

Rolling the Cilium agents took the Gateway down for 71 seconds - every
.home and serhii.link name - until the agent served Envoy its listeners
again (traps.yaml, cilium-agent-restart-takes-the-gateway-down). It was
expected to be transparent; it was not, and was found only by checking
the names afterwards.

## Next

- Alert rules as PrometheusRules - cert-manager's expiry, Flux objects not
  ready, VolSync out of sync - together with somewhere to send them
  (0008).
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
