---
id: 0003
title: restic, not OMV's rsync
status: accepted
date: 2026-09-06
tags: [backup, restic, omv, disaster-recovery]
hosts: [core]
---

OMV cannot back up its own configuration. Its rsync jobs operate on shared
folders, and `config.xml` lives in `/etc`, out of their reach, with no backup
plugin installed. Something outside OMV is therefore required no matter what —
and once one such thing exists, it may as well cover the rest.

Beyond that, rsync mirrors while restic snapshots. A file corrupted or deleted
a week ago is gone from a mirror and still present in a snapshot. Deduplication
is the practical difference day to day: a full run is ~220 MB, an incremental
a few hundred KB.

Restores were verified on 2026-09-06, including recovering `config.xml` using
only the data disk and its adjacent password copy — the case that matters when
the system SSD is the thing that died.
