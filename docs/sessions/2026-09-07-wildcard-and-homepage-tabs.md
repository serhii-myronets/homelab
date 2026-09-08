---
date: 2026-09-07
title: Kubernetes wildcard, Homepage tabs and host metrics
tags: [caddy, homepage, kubernetes, tls, cloudflare, glances, monitoring]
hosts: [core, proxmox]
---

Replaced individual Kubernetes Caddy blocks with a wildcard fallback and added
native Homepage tabs. The prior session remains historical; current routes
and publication status are recorded in [services](../services.yaml).

Read the active core cloudflared configuration update from its logs without
printing credentials. The public torrent route targets qBittorrent, not Flood;
Proxmox also has a public route. No Flood or ProxMenux public route appeared.

The first wildcard configuration passed validation but failed a real TLS
check. On-demand issuance fixed Kubernetes TLS, but exact sites needed forced
certificate automation too. The installed Caddy rejected the nested
force_automate syntax; the inline tls argument with issuer internal worked.
The failure and resolution are recorded in [traps](../traps.yaml).

Temporary containers tested the new configuration on core. Both Homepage Host
headers returned the expected service groups, and Caddy requests validated
certificates against the test CA for Kubernetes and exact core routes.
Compose and YAML validation passed. Temporary containers were removed.
Production stack redeployment and the owner's public tunnel setup remain
separate steps; no tunnel configuration was changed.

## Browser TLS report and English tab names

Changed Homepage tabs to Local and Public. Investigated the owner's browser
security warning: all five Kubernetes URLs passed normal curl certificate
validation on the owner's Mac before and after restarting production Caddy.
Grafana's served certificate had the exact grafana.home SAN and the local
Caddy issuer. The production container still held the pre-wildcard Caddyfile
while its host file was current; restarting picked up the wildcard. Homepage
also returned 200 and Jellyfin 302 with certificate validation after restart.

The reported browser warning was not reproduced. Requested the device,
browser and exact error to distinguish browser trust from another issue;
no trust settings or TLS protections were disabled.

## Host metrics, and four attempts at showing them

Installed Glances natively on core and on Proxmox, as `nobody`, out of a
virtualenv under systemd, with process collection off and the API bound to
each host's own LAN address. A container was rejected — it measures the
container, and Proxmox is not a Docker host. The reasoning is
[decision 0011](../decisions/0011-host-metrics-run-natively.md), the facts are
in [services](../services.yaml) under `host_metrics`, and the installer is
`tools/glances/install.sh`, the first executable thing here that Portainer
does not deploy.

Displaying it took four tries. Header widgets in `widgets.yaml` worked but
crowded the header. Moving to service cards with `chart: false` put four
absolutely positioned blocks in the same place, and they overlapped; 35 lines
of CSS pinned them apart and labelled them by `nth-last-child`, which worked
and was not worth keeping. Reverting to compact header widgets lost the disk
and temperature. What stands is one metric per service entry with
`chart: true`, in Core and Proxmox groups at the end of the page, and
`custom.css` is empty again. The overlap is recorded in
[traps](../traps.yaml).

## What the live hosts said that the documentation did not

Checked every claim before writing it down, and several were stale. Homepage
was still recorded as `pending-deployment` with a planned route; it is
deployed, and `homepage.home` returns 200 against the local CA. The tunnel
carries eight hostnames, not five — `qbittorrent`, `proxmenux` and `homepage`
were missing, and `torrent.serhii.link` points at Flood on `vpn:3000`, not at
qBittorrent on `vpn:8080` as recorded. The apex `serhii.link` has no DNS
record at all, so the publication hostname is `homepage.serhii.link`; the apex
survives in `HOMEPAGE_ALLOWED_HOSTS` as a leftover that reaches nothing. The
decisions index had stopped at 0008 while 0009 and 0010 existed.

One scare was not a fault: every `*.home` URL failed from core with exit 60,
including `grafana.home`, which was verified working the same day. Caddy was
up and the names resolved — core's system trust store simply does not carry
the local CA. With `--cacert` from `ca.home/root.crt`, five hostnames returned
200 or 302. Earlier verifications must have passed the certificate too, so
"200 from core" in these notes means "with the local CA supplied".

## A fifth attempt, this time measured

The owner disliked the graph cards on sight. A screenshot showed why, and
only part of it was taste: the `cpu` metric prints the processor model next
to its percentage, and four columns left the card too narrow to hold both, so
the model name and "10% Used" overlapped on both hosts. The temperature cards
spend two lines on their warning thresholds and one corner on the reading.
The graphs themselves are near-empty on load, since they only accumulate
while the page is open.

The widget has no option to hide the model name — `metric`, `chart`,
`pointsLimit`, `refreshInterval` and `diskUnits` are the whole list — so the
fix is width. Offered four shapes; the owner chose to keep all four metrics
and widen the cards. `columns: 2` it is.

Verified rather than assumed. A temporary Homepage on core, port 3001, served
a copy of the config from `/tmp/hp-preview`, and screenshots showed the model
name and the percentage separating cleanly at about 600 px while still
colliding at a quarter of the width. Two earlier previews were misleading
before that: without tabs Homepage lays groups out as a grid, so the metric
groups came out narrow and vertical instead of full-width rows, and neither
reproduced production. Cutting the config down to only the Core and Proxmox
groups gave a card the width production will give it. The preview container
and its directory were removed.

## Six metrics a host, three to a row

The owner asked for six metrics per host, three to a row, and a card about a
third shorter. The first two happened; the third did not, and deliberately.

Six needed two more readings per host that actually exist. The live API
supplied them: `network:enp1s0` on core and `network:vmbr0` on Proxmox, core's
root filesystem beside its data disk, and `disk:nvme0n1` for Proxmox, which
has only one filesystem worth showing. All twelve cards were seen carrying
real values — throughput, read and write rates, free space — before anything
was committed.

Height would have cost a customisation. The chart row is a Tailwind
`h-[68px]` on `.service-container.chart`, and there is no setting for it, so
shortening it means CSS overriding the framework — the same kind of override
deleted earlier the same day. The owner said height was not worth that, so
`custom.css` stays empty.

Three columns turned out to be enough anyway. At roughly 390 px the processor
model and its percentage still separate on both hosts, so the overlap that
started all of this does not come back.

Two previews had to be discarded first. Homepage's tab bar does not hydrate
in a temporary container — no `role="tab"` in the DOM — and without tabs it
lays groups out as a masonry grid, ignoring `style: row` and `columns`
completely. Production gives a group `basis-full` and a `grid-cols-N`; the
preview gave it `xl:basis-1/4` and stacked the cards. Spellings of
HOMEPAGE_ALLOWED_HOSTS with and without the port made no difference, nor did
telling the browser to treat the origin as secure; the cause was not found.
The way through was preview-only CSS reproducing what tabs do, kept out of
the commit. It is in [traps](../traps.yaml).

An ssh tunnel to reach the preview as a secure origin failed too: core's
sshd carries `AllowTcpForwarding no`, so `ssh -L` opens a local listener that
goes nowhere and times out without an error. That is now in
[hosts/core](../hosts/core.yaml).
