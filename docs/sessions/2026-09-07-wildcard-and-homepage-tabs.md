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
