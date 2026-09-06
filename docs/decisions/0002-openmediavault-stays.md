---
id: 0002
title: OpenMediaVault stays, for now
status: accepted
date: 2026-09-06
tags: [omv, os, gitops, migration]
hosts: [nas]
supersedes_consideration: [truenas, nixos, debian-ansible]
---

It earns very little: two SMB shares and a disk mount, with only the five base
packages installed and no plugins. By hand that is about twenty lines of
`fstab` and `smb.conf`.

What made it actively harmful was its Docker Compose plugin, which generated
files marked *do not edit* and kept a second, drifting copy of every stack —
the source of both documentation errors found on 2026-09-06. That plugin is
gone. What remains does not touch git, so the cost of keeping it is now close
to zero, while migrating off it is a weekend with a mounted 1.7 TB disk at
stake.

Its configuration lives entirely in `/etc/openmediavault/config.xml`, which the
backup carries. Restoring that one file brings back shares, mounts, SMART,
users and network.

`omv-confdbadm` has `read` and `update`, so the configuration is scriptable in
principle, but with undocumented model IDs and JSON blobs it is an internal
admin tool rather than an IaC interface.

The alternatives are recorded in [0004](0004-truenas-ruled-out.md) and
[0005](0005-consolidate-to-proxmox.md).
