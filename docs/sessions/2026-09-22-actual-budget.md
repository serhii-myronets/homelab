---
date: 2026-09-22
title: Add Actual Budget on the Beelink
tags: [beelink, actual-budget, finance, flux, backup]
hosts: [beelink]
---

# Add Actual Budget on the Beelink

The owner chose Actual Budget as a local-only household budgeting service. It
is served at `https://actual.home` by the existing Gateway and home
certificate, never through the public Cloudflare tunnel. The official
`actualbudget/actual-server:26.9.0` image runs unprivileged as UID/GID 1001
and stores its password database and encrypted budget files together under
`/data` on a 2 GiB LVM claim. VolSync copies that claim to R2 each hour at
minute 35; the first source backup completed in 33 seconds.

The initial pod crashed before listening because Kubernetes injected
`ACTUAL_PORT=tcp://...` from the identically named Service. Actual reads that
environment variable as its numeric listen port. This was the already-known
service-link collision recorded for Paperless, so `enableServiceLinks: false`
was added to the pod spec. The replacement pod was Ready, served HTTP 200
through the Gateway with Actual's required COOP/COEP headers, and the renewed
certificate listed `actual.home`.

No server password, budget, account or SimpleFIN connection was created by
automation. The owner creates those in Actual's UI.
