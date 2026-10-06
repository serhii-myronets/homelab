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

The owner asked what the new metrics cost: about 100 MiB more across
VMSingle and vmagent and 20 MB of disk a day, for 9k series. Kept as they
are; most are worth something only once a rule reads them.

So rules came next (0045): PrometheusRules beside each component for what
the chart's rules miss, each evaluated against VMSingle before the push.
Three of the chart's rules went off as permanent noise. Only
LVMVolumesNotReported fires, for controlplane's thin pool.

The services themselves expose no metrics here, and need none yet:
kube-state-metrics sees their pods, cAdvisor their use, Envoy their
requests and errors, Gatus whether they answer.

## worker-1 untainted

The owner asked what removing worker-1's taint could break. Nothing at
once - running pods are not evicted - but unpinned pods would drift there
on restarts, worker-1's loss would take more with it, and the GPU plugin
would offer the UHD 600. Claims turned out safe: the LVM driver reports no
`lvm` capacity on worker-1, so the scheduler keeps them on controlplane.

So (0046): the GPU plugin pinned to controlplane first, then the taint
out of worker-1's kubelet registration in Talos - dry run, no reboot,
`terraform apply` of the read plan - and off the node with kubectl, the
tolerations out of the manifests, and cloudflared at one replica per node.
Its first rollout put both replicas on worker-1 until the spread counted
one revision only (traps.yaml).

## Loki beside VictoriaLogs

Asked what Loki would cost, the owner chose to run it beside VictoriaLogs
and compare (0047). Loki 3.6 in single-binary mode on worker-1, its
config checked with Loki's own binary before the push; the collector
writes to both. Two things in the chart's defaults needed undoing: its
cluster-scale extras (caches, gateway, canary, MinIO), and its monitor
stamping `cluster="loki"` on every series, which `clusterLabelOverride`
fixed.

## The next day: Loki alone, and the backup the taint had held

Measured side by side after thirteen hours, the two stores matched line
for line and differed only by fractions of a second; the owner chose Loki
(0047) and VictoriaLogs went, its volume deleted. The lab's logs have
nowhere to go until it moves to the collector.

The new CronJobNotSucceeding rule caught the night's etcd backup failing:
its pod had landed on worker-1, whose taint had been its only pin, and
talosctl cannot snapshot etcd there (traps.yaml). It is pinned to the
control-plane role; a manual run succeeded on controlplane.

## Next

- nvme-thinpool has the same unspoken pin: recreating it with a node
  selector reruns its LVM script on controlplane's disk once - the
  owner's call.
- The lab onto the collector, writing to Loki through ingest.home.
- Somewhere to send the alerts (0008): a Telegram bot and a
  healthchecks.io account, which only the owner can create.
- VolSync's restore snapshots of 2026-09-30 on controlplane: the owner's
  call whether to delete them, which would let the LVM driver report the
  thin pool again.
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
