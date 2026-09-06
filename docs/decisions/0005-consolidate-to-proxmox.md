---
id: 0005
title: Fold everything into the Proxmox box
status: open
date: 2026-09-06
tags: [consolidation, proxmox, lxc, terraform, gitops]
hosts: [nas, proxmox]
---

Move the stacks and the data disk onto `proxmox`, and switch the NAS off.

## For

The hardware is not close: an i9-12900HK with 62 GB against a Celeron J4125
with 7.6 GB, and Iris Xe for Jellyfin instead of UHD 600.

Terraform already describes infrastructure on that box, so a container
definition would land in git and OMV would disappear along with the last piece
that cannot. Backups become `vzdump` of a whole container, far simpler than
restoring `config.xml`, mounting a disk and redeploying stacks.

The moves are physically available: a free SATA controller for the disk, and
the network is easier than it first looked. `192.168.8.0/24` and `10.1.1.0/24`
are VLAN 1 and VLAN 10 on the router's single `br-lan` bridge, with `lan1`
untagged into VLAN 10 and `lan2`–`lan5` untagged into VLAN 1. So a container
can reach the main LAN either by cabling `enp3s0` into any of `lan2`–`lan5`,
or by making `lan1` a trunk and adding a tagged sub-interface on the Proxmox
side — no second cable at all.

Note that IOMMU is off, so handing the SATA controller to a *VM* would need a
kernel cmdline change and a reboot. An LXC with a bind mount avoids that
entirely, which is another reason to prefer one.

## Against

That box is the laboratory — clusters get destroyed and rebuilt on it through
Terraform. The NAS's real value is that it is boring: nothing touches it, so it
keeps working. Consolidating puts the media, the torrents and the shares one
stray `terraform destroy` away from the experiments.

Guest RAM is already over-allocated on paper, though real use leaves room. The
Proxmox box has no backups of its own either.

## What would make it safe

Separate Terraform state for the production container from the Talos
playground, so a destroy in one cannot reach the other. With that discipline
the risk is ordinary; without it the point of a separate box is lost.

## If it happens

Do not carry OMV across. In an LXC it fights the container boundary over disks,
SMART and mounts — the same class of problem as the compose plugin, with
another layer on top. A plain Debian container running only Samba, defined in
Terraform, is smaller and closer to where everything else already lives.
