---
date: 2026-09-22
title: Add Uptime Kuma on the Beelink
tags: [beelink, uptime-kuma, monitoring, flux, backup]
hosts: [beelink]
---

# Add Uptime Kuma on the Beelink

The owner chose Uptime Kuma on the Beelink for local service and router
monitoring, after rejecting core as its host. The service is intentionally
local-only at `https://kuma.home`; the home certificate was reissued and the
Gateway returned the application's setup redirect.

Kuma runs the rootless `louislam/uptime-kuma:2.5.5-rootless` image. Its SQLite
database and write-ahead log live on a 2 GiB LVM claim, backed up through
VolSync to R2 at minute 30. The first claim hit the existing VolSync/OpenEBS
populator race: the PV bound but its LVM volume did not exist. The pod was
scaled down, the fresh empty claim and its incomplete source snapshot were
deleted, then Flux recreated the claim. The second claim bound, the pod became
Ready, and its source backup completed at 05:43 UTC. This is the established
recovery in `traps.yaml`; no user data existed on the first claim.

No account, monitor or notification was configured through the API or a
database write. Those will be set in Kuma's UI by the owner. The deployment
does not close the external-observer gap: if the Beelink is down, so is Kuma.
