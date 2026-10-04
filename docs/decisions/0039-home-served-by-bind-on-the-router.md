---
id: "0039"
title: .home is served by BIND on the router, written by each cluster's external-dns
date: 2026-10-03
status: accepted
tags: [router, dns, bind, external-dns, adguard]
hosts: [router, core, proxmox]
amends: ["0036"]
---

# .home is served by BIND on the router, written by each cluster's external-dns

The owner wants one local domain, `.home`, for core and for the lab, each
name published by the cluster that serves it - the way external-dns already
publishes `serhii.link` in Cloudflare. Until now one AdGuard rewrite,
`*.home -> 192.168.8.15`, sent every `.home` name to core's Gateway, so the
lab could have none.

## What was weighed

- **external-dns writing to AdGuard Home** through its webhook. AdGuard on
  this firmware admits only GL.iNet's own admin session (`--glinet`; the
  middleware is upstream's `authglinet.go` and excludes AdGuard's own users).
  It was tried on 2026-10-03 with `--glinet` removed and undone the same day:
  it took AdGuard out from behind the router's login, edited two files the
  firmware owns and loses on upgrade, and gave each cluster a credential that
  could rewrite the answer for any name in the house.
- **A proxy that logs into the router as root** to borrow GL.iNet's session
  cookie: the router's root password in a cluster. Refused.
- **An authoritative server on core.** Fresh software, but `.home` - the
  lab's names included - would depend on core.
- **One on the router.** Its feed has only 2022-era builds: `bind-server`
  9.18.7 and `knot` 3.2.1 with dynamic updates, `pdns` 4.4 past end of life,
  the rest resolvers and proxies. No modern static build of any of them.

## What was chosen

BIND 9.18.7 from the router's feed, authoritative for `home.` on port 5300,
LAN and loopback only, no recursion (`router/bind/`). AdGuard keeps
answering the house and forwards `.home` to it - one upstream line,
`[/home/]127.0.0.1:5300`, set in AdGuard's own UI. Each cluster's
external-dns writes its names over RFC 2136 with a TSIG key of its own, kept
in that cluster's Infisical project at /system/bind, and owns them through
the TXT registry - `beelink` on core, `lab` on the lab - so neither touches
the other's.

It sits under 0036's exception: a package from the router's own feed and
that package's own configuration, nothing GL.iNet manages. AdGuard and its
login stay as the firmware ships them.

## What it costs

- The build is from 2022. It answers only the LAN on a port nothing outside
  uses, recurses for no one, and accepts changes only signed.
- A firmware upgrade keeps `/etc/bind` and drops the package: until
  `router/bind/install.sh` runs again, `.home` does not resolve.
- Either key may write any `.home` name - BIND's update policy cannot tell
  the clusters' names apart; external-dns' registry does.
- Certificates still list each `.home` name: a wildcard directly under a
  top-level name is refused (traps.yaml, no-wildcard-under-a-top-level-name).
