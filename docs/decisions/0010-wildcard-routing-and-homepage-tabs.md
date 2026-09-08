---
id: 0010
title: Route Kubernetes through a local wildcard and separate dashboard tabs
date: 2026-09-07
status: accepted
tags: [caddy, homepage, kubernetes, tls]
hosts: [core, proxmox]
---

Use a wildcard fallback for Kubernetes while retaining exact routes for core.
This avoids a Caddy edit for every new HTTPRoute. A separate local suffix was
considered but would require changing existing hostnames and dashboard links.

The wildcard routes requests, while TLS uses individual local certificates;
see the wildcard-certificate failure in [traps](../traps.yaml). Exact core
sites explicitly automate their own certificates.

Use Homepage's native tabs for local and public cards rather than custom
JavaScript. The public view only contains verified tunnel routes; separate
bookmarks would duplicate those cards. Tabs are navigation, not authorization.
Preparing the public allowed host does not create or publish its tunnel route.
