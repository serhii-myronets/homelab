---
id: "0038"
title: AdGuard Home on the router runs outside GL.iNet's login, so external-dns can write .home
date: 2026-10-03
status: accepted
tags: [router, adguard, dns, external-dns, ssh]
hosts: [router, core, proxmox]
amends: ["0007"]
---

# AdGuard Home on the router runs outside GL.iNet's login, so external-dns can write .home

The owner wants one local domain, `.home`, for both clusters, with each name
published by the cluster that serves it - core's and the lab's - the way
external-dns already publishes `serhii.link` in Cloudflare. That needs an
external-dns that can write to AdGuard Home, which answers the house's DNS.

## Why it needed the router changed

Firmware 4.9 and later run AdGuard Home with `--glinet`: its API admits only
GL.iNet's own admin session (the `Admin-Token` cookie) and answers 401 to
anything else, AdGuard's own users included. GL.iNet acknowledged this on
its forum on 2026-06-24 and offers no token for programs; its suggested way
out is the one taken here. The other way out found - a proxy that logs into
the router's RPC as root and forwards the session cookie - would have put
the router's root password in a cluster, and was refused.

## What was changed, over ssh, on 2026-10-03

- `/etc/AdGuardHome/config.yaml`: one AdGuard user per cluster in place of
  `users: []`, each with its password in that cluster's Infisical project at
  /system/adguard - `lab` in proxmox-lab now, `core` in homelab when core
  publishes `.home`.
- `/etc/init.d/adguardhome`: `--glinet` removed from the command line.

`router/adguard/install.sh` makes both changes, and makes them again after a
firmware upgrade; it backs up both files first, to `/root/agh-backup-<time>`.
The first, by hand, is in `/root/agh-backup-20261003-200907`. Verified the
same day, also after a reboot: the API answers 200 with a user and 401
without, DNS answers as before, `*.home -> 192.168.8.15` still resolves.

## The exception to 0007, and its cost

This is the second exception to 0007 after 0036, and a different kind:
it edits files the firmware owns. What it costs:

- AdGuard's page in the GL.iNet UI no longer opens behind the router's login;
  it asks for an AdGuard user. Turning AdGuard on and off in that UI still
  works - that goes through uci.
- A firmware upgrade restores the init script and with it `--glinet`. Both
  clusters' external-dns then get 401: names already published stay, new
  ones do not appear until the line is removed again. Whether the user in
  config.yaml survives an upgrade is not known.
- Whoever holds either credential can rewrite DNS answers for the whole
  house: AdGuard has no read-only or per-name user. Each cluster holds only
  its own, so either can be revoked alone.

## What follows

Each cluster gets an external-dns with the AdGuard webhook
(github.com/muhlba91/external-dns-provider-adguard), owner `beelink` on
core and `lab` on the lab, so neither touches the other's records. The
wildcard rewrite `*.home -> 192.168.8.15` goes once core publishes its own
names. Certificates still list each `.home` name: a wildcard directly under
a top-level name is refused (traps.yaml, no-wildcard-under-a-top-level-name).
