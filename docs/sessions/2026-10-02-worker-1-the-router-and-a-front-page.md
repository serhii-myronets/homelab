---
date: 2026-10-02
title: worker-1 given its job, a watcher on the router, and a front page
tags: [worker-1, router, gatus, homepage, observability, infisical, volsync, cilium, immich, torrent, traps]
hosts: [core, worker-1, router]
---

# worker-1 given its job, a watcher on the router, and a front page

Three days, from the evening after the rebuild to 2026-10-02. What follows
is the story; every fact it touches already lives in hosts/, traps.yaml or
decisions/.

## What worker-1 is for

The ORICO became the thin pool `ssd` behind `lvm-worker-1`, and the taint was
renamed `homelab/dedicated=worker-1` - with kubectl too, as the kubelet sets
it only at registration. Moving Sure there stopped at VolSync, whose movers
take no tolerations; namespace-wide tolerations were dry-run and dropped, and
the rule became that worker-1 holds nothing VolSync backs up (0035). Taking
the taint off was weighed and left: only 1.3 Gi of requests would drift, and
CoreDNS with them, onto the older machine. Longhorn and other network block
storage were weighed and left for a third node.

Immich's machine learning was tried beside the running one. The Celeron's
missing AVX did not matter; the UHD 600 did - its face detector scored
everything 0.5 (traps.yaml, uhd-600-finds-no-faces). On OpenVINO's CPU it was
right and 2.5x slower, so it stays on controlplane until the metrics say
otherwise. The metrics came back instead: the VictoriaMetrics stack moved out
of the archive onto worker-1 and the ORICO, with the apiserver SLO rules
switched off for lack of the buckets they need. FlareSolverr moved too.

## Two faults the new eyes found

During a phone import controlplane fell to 0.57 GiB free. Talos's OOM
controller took Uptime Kuma's VolSync mover first - BestEffort, no
resources - and the restic lock it left failed every later backup until
unlocked; movers now carry a memory limit. Immich's server died three times
inside its own 3Gi and now may reach 4Gi with 3Gi reserved.

NodeDiskIOSaturation, on the first day the alert could be seen, was
qBittorrent filling its staging volume on the WD while the thin pool zeroed
every fresh chunk. Zeroing is off on both pools and qBittorrent writes
plainly, three downloads at a time (traps.yaml, downloads-saturate-the-wd).

## The watcher, and why it is on the router

Gatus first ran on worker-1 and at once found torrent.home answering 503
from there: the Service's externalTrafficPolicy: Local, which Cilium's Envoy
honours for Gateway traffic (traps.yaml). It then moved to the router -
outside both nodes - as a static binary installed by router/gatus/install.sh,
the one narrow exception to 0007 (0036). A loop pulling the checks from main
was built and dropped before it ran: it would have handed anyone with push
access a say in what the router fetches. The router resolves through the
WAN's servers, so the checks ask 192.168.8.1:53. Uptime Kuma, which had never
held a monitor in any backup, went to the archive with the worker-1 Gatus.

gatus.home through the Gateway timed out: Cilium's Envoy cannot reach an
address outside the cluster, a choice its maintainers stand by
(cilium/cilium#46798; traps.yaml). A socat pod carries it. Replacing the
Gateway with Envoy Gateway was weighed and left for later.

## dash.home

Homepage, on worker-1: every service with its site check through the
Gateway and its pods' load, live numbers from the *arr, Seerr, qBittorrent,
Immich, Jellyfin and Gatus, a calendar, and a Health row read straight from
VictoriaMetrics - free space on each HDD, the fullest PVC, swap, backups
behind, etcd's last run, alerts firing. VolSync's own metrics are scraped now,
through its metrics-reader role. The router got its node exporter (0036 again)
for the WAN numbers. AdGuard's widget is impossible: GL.iNet's build of it
answers 401 even on loopback without the GL session, so the router's root
password would have to live in the cluster; a test with it confirmed the 401
and the password was deleted.

## Housekeeping

Infisical was laid out as the repository is - /system, /services, /router,
/archive - every secret copied, verified, switched and the old paths removed
with all fifteen Kubernetes secrets byte-identical. Reloader now restarts the
Deployments whose secrets change. In Radarr, the title-search trackers drop
the year, since TMDb and Toloka disagree for films like The Gentlemen;
RuTracker was switched off at the owner's wish, in Prowlarr and in both apps.

One slip: a Prowlarr API key reached the screen inside an error message while
testing RuTracker. It was rotated on 2026-10-02 - a new key in config.xml,
synced to Sonarr and Radarr, every enabled indexer tested, and Infisical's
copy replaced, which Reloader carried to Homepage.

Still open:
- A second copy of Immich's originals, now about 103 GB - R2, the ORICO, or both.
- A daily backup of the router's configuration, through a forced-command
  ssh key added in LuCI.
- Alerting (0008): a Telegram bot and a healthchecks.io account, then
  Gatus's alerting block and its heartbeat.
- Terraform state in R2.
