---
date: 2026-09-30
title: satellite as a cluster, then a worker, and core rebuilt under fixed names
tags: [satellite, core, talos, rebuild, volsync, observability, tls, naming, traps]
hosts: [core, satellite, worker-1, router]
---

# satellite as a cluster, then a worker, and core rebuilt under fixed names

## A second cluster, built in a day

The old OpenMediaVault box became satellite, its own Talos cluster, to watch
core and keep copies (0032). It got its own Terraform, platform and Flux
tree; OpenEBS LVM over the whole ORICO; a Gateway at .21 with its own
Cloudflare tunnel and an external-dns that owned its records as satellite; one
Headlamp showing both clusters through an `edit` account on core; and the
VictoriaMetrics stack from the archive, with VictoriaLogs added.

Several things failed on the way. Infisical PKI was the first choice for
satellite's certificates and its free plan refused the last step, importing
an intermediate signed by home-ca; a locally made, name-constrained
intermediate replaced it (0033). Headlamp in-cluster ignored KUBECONFIG and
wanted `-kubeconfig`. The first install was refused because Talos reports no
serial for these SATA disks. An apply of a raised apiserver limit hung in
"Still modifying": `ignore_changes` on node and endpoint had pinned the
maintenance address in state, so it went to a DHCP address nothing answered.
The node also rebooted during that attempt and came back with the old
configuration; why was never established - its logs went with the reboot.

## Back into core

With the cluster built, the arithmetic was plain: 1.9 GiB of satellite's 7.6
went on its own platform, and the glue between two clusters kept growing.
The owner judged the independence not worth it - a T7 on the router for
copies and an outside heartbeat for alerts were enough - and satellite joined
core as a worker (0034). Its route and DNS record were released first, while
its external-dns could still delete them; Headlamp went back to core.
`machine.nodeTaints` failed on the worker - NodeRestriction forbids a node to
taint itself - so the taint moved to the kubelet's registerWithTaints, and
the Node was deleted to register again.

## core rebuilt

core's node still had the generated name talos-lqh-j5o, and all 18 of its
OpenEBS volumes were pinned to it by a field that cannot change. So the
cluster was rebuilt: `core`, nodes `controlplane` and `worker-1`. Before the
reset, home-ca moved into Infisical - it had existed only in the cluster, and
a rebuild would have minted a new root for every device - a manual VolSync
backup ran for all seven services, and an etcd snapshot went to the Mac.

In maintenance mode the NVMe names had swapped, and the configuration still
named nvme1n1 - now the WD with every volume - as the install disk. The
Talos reference confirmed diskSelector takes priority; the name was removed
anyway. After the reset, bootstrap, Helmfile and Flux, all seven services
came back from R2 within two minutes of each other, Immich with its 7,264
assets. The old logical volumes stayed on the WD as a fallback.

The kubeconfig Terraform handed out still said beelink: the resource keeps
what it generated in state and nothing in it had changed. `-replace` made a
new one.

## Left

Cleaned the same evening, once the services had come back: the 18 old
cluster's volumes on the WD - listed as whatever no PV and no LVMVolume
named, which also caught the seven LVMSnapshots VolSync's restores had just
made; those stayed (0024) - leaving the thin pool at 1%, most of the old use
having been caches; the ORICO's volume group, from a privileged pod on
worker-1 after `talosctl wipe disk` refused a disk LVM held; the satellite
tunnel; and `/satellite` and `/cloudflared/satellite` in Infisical.

## The documentation pass

The repository was then cut down for a fresh agent: traps for things that
can no longer happen (Tailscale, Argo CD, Pulse, Caddy, the satellite
cluster's Headlamp) went, eight of 67; core.yaml lost what the manifests
already say - images, versions, migration history - and halved; backups.yaml
lost the old box's restic job; decisions and sessions about retired setups
left the tree for git history; the FluxInstance dropped the Argo field-manager
patches this cluster never needed. AGENTS.md now carries the habits the day
paid for: plan to a file before a Terraform apply, dry-run Talos, never print
a secret, and zsh's two traps.

## worker-1 put to work

The taint lost the name satellite and became homelab/dedicated=worker-1,
changed with kubectl as well, since the kubelet sets it only at
registration. The ORICO became the thin pool `ssd` behind the class
lvm-worker-1. FlareSolverr moved there.

Sure was to follow and did not: VolSync's movers take no tolerations, so a
backed-up claim on worker-1 could be neither restored nor backed up. Opening
namespaces to it through two admission plugins was planned and dry-run, then
dropped - worker-1 holds nothing VolSync backs up (0035).

Immich's machine learning was tried there beside the running one. The
Celeron's missing AVX did not matter; the UHD 600 did: OpenVINO's GPU plugin
scored every face 0.5 and found none, while CLIP came out identical to
controlplane's. On OpenVINO's CPU device it was correct and about 2.5x slower.
It stays on controlplane until Grafana shows whether its peaks actually hurt.

The VictoriaMetrics stack came out of the archive onto worker-1: every
target up, logs from both nodes, grafana.home answering, about 1.1 GiB. The
apiserver's SLO rules were switched off - they are built from the buckets
the scrape drops, and kept RecordingRulesNoData firing.

Still open:
- Nothing reaches anyone when an alert fires: Alertmanager has no receiver
  (0008).
- A local copy of Immich's originals on the ORICO, through a rest-server on
  worker-1, is the next use for the disk.
- The router: a T7 behind restic's append-only rest-server, node-exporter,
  and a watcher that reports to healthchecks.io - planned, not built.
