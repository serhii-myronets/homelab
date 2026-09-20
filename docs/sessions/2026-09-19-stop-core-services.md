---
date: 2026-09-19
title: Stop the retained core services after the Beelink migration
tags: [core, beelink, migration, docker, cleanup]
---

The Beelink cluster was checked before the handover: its Gateway was
programmed at `192.168.8.15`, every Argo Application was Synced and Healthy,
and the local certificate was Ready for its explicit names.

Core still ran Caddy, cloudflared, Homepage, Pulse, Portainer, Jellyfin,
Gluetun, qBittorrent and Flood despite the previous handoff saying that the
media services were stopped. The owner chose to stop every one of those
containers. They, their Docker volumes, bind-mounted data, compose files,
secrets and the core checkout remain in place for recovery; nothing was
deleted.

The router's `*.home` rewrite points at the Beelink Gateway. Core's former
`.home` routes therefore remain inactive until those services move or the
owner chooses explicit router rewrites to core.

Documentation now reflects the Gateway address and the cert-manager local CA.
The Gateway certificate is not a `*.home` wildcard: it lists each served name,
because clients reject a wildcard immediately beneath a top-level domain.
