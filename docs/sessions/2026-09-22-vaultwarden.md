---
date: 2026-09-22
title: Add a household password vault
tags: [beelink, vaultwarden, passwords, flux, backup]
hosts: [beelink]
---

# Add a household password vault

Vaultwarden was added as the household password vault after the owner chose to
move beyond Chrome's built-in password storage. It runs `vaultwarden/server`
1.37.3 on a 2 GiB LVM claim. Its SQLite database, WAL, configuration and
attachments share that one claim, so VolSync's hourly snapshot at minute 25
catches a consistent database and copies it to R2 under `volsync/vaultwarden`.

The only route is `https://vault.home`. The service is deliberately not
published: Cloudflare Access is an interactive browser gate and would not be a
transparent path for Bitwarden extensions or mobile clients. The home
certificate was reissued to include `vault.home`; the route returned 200 and
`/alive` returned the Vaultwarden timestamp through the Gateway. The pod was
Ready and the Flux Kustomization applied revision `45235a7`.

Registration is open only on the LAN while the household creates its initial
accounts. No SMTP or administrative token was added, so there is no invitation
workflow yet. After accounts exist, registration can be closed by changing the
manifest without touching the stored vaults.

The initial empty-volume VolSync restore completed. The first scheduled
backup will run at minute 25 of the next hour; it was not artificially
triggered while the deployment was being verified.

SimpleFIN's public institution search was checked for a possible future Actual
Budget trial. Its catalog listed Bank of America, Chase Bank and Wells Fargo;
it returned no result for Webull.
