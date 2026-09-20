---
date: 2026-09-19
title: Use one route per torrent service
tags: [beelink, cloudflare, gateway, torrent, qbittorrent]
---

The torrent component had three routes: one public `flood` route, one local
`flood-home` route, and the qBittorrent route. The names described the Flood
implementation rather than the service users reach.

It now has two routes only. `torrent` sends `torrent.home` and
`torrent.serhii.link` to Flood on port 3000; `qbittorrent` sends
`qbittorrent.home` and `qbittorrent.serhii.link` to port 8080. external-dns
removes the unused `flood.serhii.link` record.
