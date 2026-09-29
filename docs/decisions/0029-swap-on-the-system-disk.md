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

## Tested the same evening

A throwaway pod took hot memory in 512 MB steps towards a 6 GiB limit. Swap
started at about 2 GB allocated; by 5.6 GB, 1.9 GB had left memory, mostly
compressed in zswap at about 3:1 and only a few hundred MB written to disk,
and available memory never fell below about 1.2 GB. Twenty-three pods gave
up pages, the idle ones most: Sure 509 MiB, library 417, Jellyfin 173,
machine learning 128, flaresolverr 98, Uptime Kuma 93, Immich's Postgres 66.
The Immich server, Guaranteed, gave none. The pod was OOM-killed by its own
limit; Talos's OOM controller did not act, and every service kept answering.

Swapped pages stay out until something touches them, so an idle service now
costs the node much less real memory; the price is a slower first request
when it wakes. Swap does not change scheduling: requests still reserve 88% of
the node's memory, and a new service is sized against what is left of that.

## Tested again, with a monitoring stack's worth of memory

A second run added what a small VictoriaMetrics stack would hold - a pod
keeping 1 GiB hot - and real work, Smart Search over every asset, beside the
same climbing pod. Swap reached 3.5 GB with up to 1.7 GB in zswap; the run
was stopped when available memory fell to about 290 MB. Talos's OOM
controller acted nine times and took Immich machine learning every time.
Every service kept answering. At the bottom, the controller manager, the
scheduler and cilium-operator each exited once: etcd was too slow for them to
renew their leader-election leases. The first two now run with leader
election off - there is one control plane - and the operator with a 60 s
lease and 40 s to renew it.

So a 1 GiB monitoring stack fits ordinary days and ordinary imports, with
available memory staying near a gigabyte; at the extreme, machine learning
dies in a loop until the pressure passes.
