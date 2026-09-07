---
id: 0006
title: A third copy on the Proxmox box
status: accepted
date: 2026-09-06
tags: [backup, disaster-recovery, restic, sftp]
hosts: [core, proxmox]
---

Both restic repositories were inside the NAS. The cross-disk arrangement
survives a disk dying and nothing else: fire, theft or a dead power supply took
the configuration along with the data.

A third repository now sits on `proxmox` at `/var/lib/vz/backups/restic`,
reached over sftp, holding everything the two local ones hold between them.
134 MB at 1.70x compression, a few MB a day after that, against 78 GB free.

## Access

A dedicated ed25519 key, `/root/.ssh/id_ed25519_backup`, authorised on the far
side as `restrict,command="internal-sftp"`. That key opens a file transfer and
nothing else — verified by trying: `ssh` with it answers *"This service allows
sftp connections only."* A `proxmox-backup` alias in `/root/.ssh/config` keeps
it from being used for anything but the backup.

`core/backup/install.sh` generates the key, writes the alias, and initialises
the repository. If the far side has not authorised the key yet it prints the
one line that does so and carries on — the local backups do not depend on it.

## What this does and does not cover

It covers losing the machine. Restoring needs only restic and the repository
password: the repository is plain files, readable from anything that can reach
them, so the ssh key is a convenience for the nightly job rather than part of
recovery.

It does not cover losing the building. All three copies are in one room on one
breaker. Calling this an off-site backup would be a lie, and the distinction
matters for what it protects against.

restic speaks B2 and S3 natively, so a genuinely off-site fourth copy is
another two lines and a couple of dollars a month. That is the remaining step,
and it is deliberately not taken yet.

## Verified

2026-09-06: `config.xml` restored out of the remote repository and compared
against the live file — identical SHA256.
