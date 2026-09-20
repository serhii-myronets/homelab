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
temporary path. qBittorrent is configured to write unfinished downloads there
and copy finished files to `/downloads` on the HDD. Its read and write I/O
modes disable the OS cache, so the pod should not retain the HDD's page cache.
The SSD claim is disposable and deliberately excluded from backups.

The rollout bound the claim, but qBittorrent could not start because Gluetun
received `AUTH_FAILED` from NordVPN. The ExternalSecret was healthy: it proved
that the two values were fetched from Infisical, not that NordVPN accepts
them. The credentials must be replaced in Infisical before the client settings
can be verified in a running pod.
