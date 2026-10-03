---
id: "0036"
title: Gatus and a metrics exporter run on the router, installed over ssh
date: 2026-10-01
status: accepted
tags: [router, gatus, monitoring, alerting, ssh]
hosts: [router, core, worker-1]
amends: ["0007"]
---

# Gatus and a metrics exporter run on the router, installed over ssh

The house needed a watcher that does not share the fate of what it watches -
the "watcher on the router" in service-ideas. Gatus ran first on worker-1 and
found a real fault on its first run (traps.yaml,
gateway-503s-a-service-with-local-traffic-policy), but a pod on worker-1 says
nothing when worker-1 itself is gone. On the router it depends on neither
node, on Talos or on Kubernetes, and it sees the services the way every
device in the house does: the router's DNS, then the Gateway.

It fits there. The GL-MT6000 had about 465 MB of memory available and 6.7 GB
of storage free on 2026-10-01; Gatus is one static aarch64 binary, about 30-40
MB in memory.

## The exception to 0007

0007 says the router is configured through its own UI, never over ssh,
because GL.iNet regenerates its configuration from its own state. Gatus
touches none of that state: no uci section, no firewall rule, no network
setting, no cron entry. It lives in /opt/gatus and /etc/gatus, starts from
/etc/init.d/gatus, and adds three paths to /etc/sysupgrade.conf so a firmware
upgrade keeps it. The firmware has nothing of its own there to overwrite, which
is the distinction 0007 already draws for LuCI-only settings.

So the exception is narrow: `router/gatus/install.sh` and
`router/node-exporter/install.sh` are the only things in this repository that
write to the router, and only to what they install. Everything else on the
router stays as 0007 has it.

## The exporter, added 2026-10-02

The same reasoning took in a second package: prometheus-node-exporter-lua,
from the router's own opkg feed, with its openwrt and wifi_stations modules,
and its own configuration set to listen on the LAN. vmagent scrapes it, so
the router's CPU, memory, WAN traffic, connections and Wi-Fi clients sit in
Grafana and on dash.home. It holds about 2 MB. A firmware upgrade keeps its
configuration but not the package; running its install.sh again restores it.

## How it stays declarative

The checks are `router/gatus/config.yaml` in Git, and `install.sh`, run from
the Mac, is the only way anything reaches the router: the binary when the
version moves, the start script and the checks when they differ from what is
there. Gatus rereads its checks on change, so editing them needs no restart.
Secrets stay on the router, in /etc/gatus/env, which the script creates empty
and never reads or writes; `install.sh restart` picks up a change to them.
History is kept in memory, to spare the router's flash.

What is lost: Flux does not reach the router. A new Gatus version is
Renovate's pull request and then `install.sh`; a new check is a commit and
then `install.sh`. A reflash loses it all (traps.yaml,
router-reflash-wipes-everything); running `install.sh` once is the whole
recovery.

## What it does not cover

Nothing inside the house can report the house going dark - the power, the
internet or the router itself. That is healthchecks.io's job: Gatus pings it
every minute, and its silence is the alert. Both wait on alerting being set
up (0008).

## Rejected

- **Gatus on worker-1 alone.** Silent when worker-1 is down, and it shares
  Cilium and the cluster's fate with what it checks. It ran for a day beside
  the router's copy and went to the archive on 2026-10-01, with Uptime Kuma,
  which had never been given a monitor.
- **Docker on the router**, to run the official image unchanged. The engine
  costs more memory than Gatus and is a second runtime on the house's most
  important box.
- **Uptime Kuma.** Its monitors live only in its own database; config as code
  needs AutoKuma, a third-party bridge last released in November 2025.
- **The router pulling its checks from main**, a loop every five minutes, as
  Flux does. Dropped before it was installed: it hands whoever can push to
  main a say in what the house's most important box fetches - with a
  Telegram token beside it - and it is one more job running on the router.
  A script run from the Mac is simpler, and the router reaches out for
  nothing.
