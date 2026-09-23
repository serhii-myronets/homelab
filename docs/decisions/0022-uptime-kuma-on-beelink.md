---
id: 0022
title: Uptime Kuma observes the Beelink from inside it
status: accepted
date: 2026-09-22
tags: [monitoring, uptime-kuma, beelink, alerts]
hosts: [beelink, router]
---

# Uptime Kuma observes the Beelink from inside it

The owner chose Uptime Kuma on the Beelink rather than on core, Proxmox or the
router. It is a small local service for HTTP/TCP checks, outage history and
notification delivery. It runs rootless, stores its SQLite database on a
backed-up LVM claim and is reachable only at `kuma.home`.

This is deliberately useful but incomplete monitoring. Kuma can tell when the
router, DNS, Gateway or an application stops answering while the Beelink is
alive. It cannot send a notification when the Beelink, its power or its LAN
path is down, because it goes down with them.

Core was not selected: it no longer serves applications and the owner did not
want to bring Docker back there for this. Proxmox is a disposable lab host;
the router cannot observe its own outage and is changed only through its UI.
An external heartbeat remains the missing observer in [0008](0008-nothing-tells-anyone-when-something-breaks.md).

Kuma starts with no account, monitor or notification channel. Those are user
data in its database and are created in its web interface, not committed to
Git. Its initial backup completed after the service became Ready; later hourly
copies protect any monitor and notification configuration.
