---
date: 2026-09-07
title: Kubernetes wildcard and local/public Homepage tabs
tags: [caddy, homepage, kubernetes, tls, cloudflare]
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
