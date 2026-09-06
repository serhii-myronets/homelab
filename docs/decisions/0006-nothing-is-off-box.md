---
id: 0006
title: Nothing is backed up off the box
status: open
date: 2026-09-06
tags: [backup, disaster-recovery, risk]
hosts: [nas, proxmox]
---

Both restic repositories are inside the NAS, so fire, theft or a dead power
supply takes the configuration along with the data.

Closing it is one more entry in `backup/backup.sh` pointing at `sftp:` on the
Proxmox box, which has 1.6 TB free. At ~220 MB it costs nothing.

This is worth more than any of the migrations under consideration and has not
been done.
