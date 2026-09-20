---
date: 2026-09-19
title: Publish Argo CD through the Beelink tunnel
tags: [beelink, argocd, cloudflare, cloudflared, external-dns]
---

Argo CD already had the local route `argocd.home`. The owner also wanted it
through Cloudflare Access, so the route gained `argocd.serhii.link`.
external-dns owns the corresponding proxied CNAME and points it at the
locally managed Beelink tunnel.
