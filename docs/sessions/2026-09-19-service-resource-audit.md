---
date: 2026-09-19
title: Audit running service and system resource use
tags: [beelink, core, kubernetes, talos, resources, audit]
---

Read-only audit using Kubernetes metrics, kubelet stats, Talos services and
processes, PostgreSQL catalog queries, and SSH to core. Router access was
read-only. Proxmox SSH timed out, so its running guests and services were not
verified. No workload configuration or service state changed during the audit.

## Measurements

Beelink node working set was 4645–4658 MiB and CPU was 0.51–0.59 cores of four.
Talos reported about 7.2 GB available memory. Memory PSI averages were zero,
and Kubernetes reported no memory, disk or PID pressure. All 19 Argo
Applications were Synced and Healthy. Running containers had no OOMKilled
last-termination status. These are short samples, not peak-load measurements.

Container working sets below come from `kubectl top`; Talos process RSS is
listed separately and must not be added to container metrics because it
includes shared pages and measures memory differently.

| Component | Observed MiB | Assessment |
|---|---:|---|
| Kubernetes API server | 1141–1142 | Largest container; no evidence from this audit to justify shrinking its caches or imposing a tight limit. |
| Controller manager / scheduler | 104–118 / 40 | Required control-plane components. |
| Cilium agent / operator / Envoy | 200 / 70–84 / 61–62 | Required network and Gateway functionality; optional Hubble is enabled inside the agent. |
| CoreDNS, two replicas | 71–72 total | One replica would save about 34–38 MiB but lose process redundancy and risk DNS interruption during replacement. |
| Argo controller / repo / server / Redis | 245–252 / 35–36 / 40 / 24 | Controller grew above the immediately post-restart reading; sustained savings from concurrency changes remain unproven. |
| Jellyfin | 334–335 | Modest current use; keep GPU acceleration and measure during actual playback/transcoding. |
| Flood / qBittorrent / Gluetun | 151–152 / 25 / 37 | Optional Flood UI is the largest part of the torrent stack. |
| PostgreSQL / Barman sidecar | 67–69 / 35–36 | Candidate for hibernation until an application needs the database. |
| CNPG / Barman operators | 46 / 17 | Remain running during database hibernation. |
| OpenEBS controller and node containers | 88–89 total | Keep CSI services; embedded snapshot-controller duplicates the standalone controller. |
| Standalone snapshot-controller | 15 | Keep one cluster-wide snapshot-controller. |
| VolSync | 34 | Keep backups; movers run temporarily. |
| cert-manager / cainjector / webhook / CA web server | 28 / 39–40 / 13 / 4 | Keep certificate automation; custom CA web server has negligible resource cost. |
| External Secrets / external-dns / cloudflared | 38 / 27 / 17 | Low overhead for secrets, public DNS and tunnel. |
| Samba / Intel GPU plugin / metrics-server | 26 / 6 / 37 | Low overhead and useful functionality. |

Talos services were healthy where a health status is provided. Process RSS
included etcd at 136 MB, kubelet at 123 MB, the workload containerd at 112 MB,
init/machined at 165 MB and the physical-console dashboard at 98 MB. The two
containerd processes serve Talos system containers and Kubernetes workloads;
they are not interchangeable duplicates. Other host processes were inspected
without finding a runaway process. CPU-time in `talosctl processes` is
cumulative, not instantaneous CPU percentage.

## Candidates, in priority order

1. Disable only OpenEBS's embedded `snapshot-controller` (about 10 MiB).
   It runs v8.2.0 without leader election, while the standalone v8.6.0
   controller uses a kube-system lease. They are not cooperating HA replicas.
   The OpenEBS chart provides `lvmController.snapshotController.enabled` for
   this case. Preserve the `csi-snapshotter` sidecar, snapshot CRDs and the
   standalone controller. Verify the pinned chart before applying.
2. Keep Flood only if its UI is useful. Removing it would avoid about 152 MiB;
   the qBittorrent UI remains available. Routes, service ports and startup
   configuration would need corresponding changes.
3. Hibernate PostgreSQL if no near-term consumer needs it. The only client
   at inspection was this audit's psql session; database `app` had no user
   tables, and both non-template databases were about 7.8 MB. Declarative CNPG
   hibernation retains PVCs while removing the database pod, saving roughly
   100 MiB in this sample. Operators remain; database service and new backups
   are unavailable until resumed. Do not delete the Cluster/PVCs for this.
4. Optional: turn off Hubble if network-flow diagnosis is not wanted. The
   in-agent flow buffer was full at 4095 entries, with about 37 flows/s;
   relay/UI are absent. Exact memory savings require a before/after test.
   Envoy must remain for the Gateway.
5. Optional: disable the Talos physical-console dashboard on a future planned
   reboot if it is unused. `talos.dashboard.disabled=1` is a kernel option;
   the measured 98 MB RSS is not a guaranteed amount of recoverable RAM.
6. Keep two CoreDNS replicas unless the small memory saving justifies reduced
   DNS continuity. Do not claim that a single node makes the second process
   entirely useless.
7. Stagger Jellyfin and torrent's hourly VolSync jobs, currently both at :15,
   to spread backup CPU and I/O peaks. Last successful runs took about 18 and
   13 seconds, so this is preventive tuning, not an observed bottleneck.

Argo, Cilium and most OpenEBS containers have no memory requests. Adding
realistic requests improves scheduling/accounting; it does not directly reduce
RAM usage. Tight memory limits based on idle samples can cause OOM failures.
The previous Argo report's 273-to-213 MiB change was measured just after a
restart; this audit measured 245–252 MiB later. A warmed-up comparison is needed
to isolate concurrency effects from restart and cache warm-up effects.

## Retained core and other hosts

Core had zero running Docker containers, about 750 MiB used memory and 7 GiB
available. Docker daemon and containerd still used about 74 and 41 MiB RSS.
Pulse agent used about 39 MiB RSS and repeatedly logged connection refused
against its stopped local server on port 7655. Stopping that unused agent is a
clear cleanup candidate; stopping Docker/containerd is conditional on retaining
core's containers only as offline rollback material.

Core still runs OMV/nginx/PHP, Samba and discovery, monitoring, SMART and
system services. Samba had an active client process, so it must not be assumed
unused. The restic backup timer is still enabled. Keep backup and disk-health
services until the old machine's data-retention role is settled. Journald RSS
was about 105 MiB; no evidence here warrants forcing a smaller cache.

Router reported roughly 340 MiB used and 587 MiB available, with low load.
Only memory/load were checked; no router configuration changed. Proxmox could
not be audited because SSH to 10.1.1.100 timed out.

## References

- [OpenEBS snapshot-controller switch](https://github.com/openebs/lvm-localpv/blob/develop/deploy/helm/charts/values.yaml)
- [Kubernetes snapshot controller and CSI sidecar roles](https://kubernetes.io/docs/concepts/storage/volume-snapshots/)
- [CNPG declarative hibernation](https://cloudnative-pg.io/docs/1.25/declarative_hibernation/)
- [Cilium Hubble](https://docs.cilium.io/en/stable/observability/hubble/setup/)
- [Talos dashboard kernel option](https://docs.siderolabs.com/talos/v1.11/reference/kernel)
- [Kubernetes resource requests and limits](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
