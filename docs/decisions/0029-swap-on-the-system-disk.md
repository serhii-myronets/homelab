---
id: "0029"
title: Swap on the system disk, behind zswap
date: 2026-09-29
status: accepted
tags: [beelink, talos, swap, zswap, memory, ephemeral]
---

# Swap on the system disk, behind zswap

The Beelink has 12 GB and runs the control plane beside every service, so an
import into Immich leaves it short of memory. It now has 16 GiB of swap: a
partition on the system disk made by Talos's SwapVolumeConfig, with zswap
compressing pages in memory first (20% pool), and kubelet's LimitedSwap, which
lets Burstable pods swap in proportion to their requests and Guaranteed ones
not at all. What it buys is room taken from memory nobody is touching - idle
*arr, Sure at night, caches - not relief from an import's hot working set.

There was no free space for the partition. EPHEMERAL filled the 128 GB system
disk, and a size cap on it only applies when the volume is created, so it was
wiped: an etcd snapshot, `talosctl reset --graceful=false --reboot
--system-labels-to-wipe=EPHEMERAL` with the cap already in the configuration,
and `talosctl bootstrap --recover-from` the snapshot. EPHEMERAL came back at
100 GiB, of which it used about 22, the swap partition after it, and the
cluster as it was; services were down for under nine minutes while images
downloaded again. The node boots through a UKI with systemd-boot, so the
GRUB failure reported with swap on the system disk (siderolabs/talos#12234)
does not apply.

A swap logical volume in the WD's volume group was the alternative, and the
recommended one at first: no wipe and no downtime. It was rejected because
Talos would not know it existed - a privileged pod would switch it on after
kubelet had already started the pods - and the owner preferred doing it once,
in the supported way. The WD's DRAM would have suited swap slightly better,
but it runs on one PCIe lane against the system disk's two.

zram, which Talos does not ship, was not an option: its kernel has zswap and
no zram module, and Sidero Labs prefer zswap (siderolabs/talos#11308).
Encrypting EPHEMERAL and swap was possible only at this moment and was left
out: without Secure Boot, Talos would key it to the machine's own identity,
which protects a disk removed from the Beelink and nothing else.
