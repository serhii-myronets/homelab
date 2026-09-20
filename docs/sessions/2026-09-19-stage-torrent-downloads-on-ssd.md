---
date: 2026-09-19
title: Stage incomplete torrent downloads on SSD
tags: [beelink, kubernetes, storage, torrent, qbittorrent]
---

qBittorrent's pod metric appeared to consume about 700 MiB. The application
process used about 45 MiB; nearly 1 GiB attributed to its cgroup was Linux file
cache for the HDD files. That cache is reclaimable under memory pressure, but
it unnecessarily counts against qBittorrent's 1 GiB container limit.

The client already had a temporary download path configured, but it was
disabled. A 50 GiB LVM claim is allocated for `/incomplete`, the enabled
temporary path. qBittorrent writes unfinished downloads there and copies
finished files to `/downloads` on the HDD. Its read and write I/O modes disable
the OS cache, so the pod no longer retains the HDD's page cache. The SSD claim
is disposable and deliberately excluded from backups.

The first Gluetun process received repeated `AUTH_FAILED` replies from one
NordVPN endpoint and was restarted by its startup probe. Its replacement
connected successfully using the unchanged ExternalSecret, so the credentials
were not changed. The claim, running configuration, tunnel, and qBittorrent
were then verified healthy.
