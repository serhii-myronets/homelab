---
date: 2026-09-29
title: Deciding which pod dies when the Beelink runs out of memory
tags: [beelink, immich, sure, talos, memory, oom, video, traps]
hosts: [beelink]
---

# Deciding which pod dies when the Beelink runs out of memory

Two phones' first imports and an upload of six re-encoded videos kept pushing
the node out of memory, and every fix until now had been to switch something
off for the duration. This session looked for a setup that holds without that.

## Six kindergarten videos, re-encoded

Six videos of 30 to 60 minutes - four interlaced MPEG-2 `.mpg` at 15-26
Mbit/s and two H.264 `.mp4` at 13 Mbit/s - held 30 GB of the 59 GB of
originals. They were re-encoded on the Mac to HEVC with libx265 CRF 20,
preset fast, deinterlaced with bwdif. Quality was measured against a CRF 12
encode of the same clip: VMAF 95.3; against the source directly the scores
were meaningless because the two decoded one frame apart. They came to 13 GB,
went into Immich through the API with the old assets' dates, matched to the
second in date and duration, and the old six went to the trash. The DV
wedding footage from 2014 - 324 clips, 53 GB - was re-encoded clip by clip the
same way to 4.6 GB on hdd-b and not yet imported; four clips failed because
nine in ten of their frames do not decode.

The T7 turned out to be NTFS, read-only on macOS, so output went to hdd-b.

## What Talos's OOM controller actually kills

The first upload died at 02:21 UTC: Talos killed the Immich server again.
Making the server Guaranteed seemed to fix it, and then at 03:58 Talos killed
kube-apiserver and Sure instead, taking the controller manager, scheduler and
cilium-operator down with them. Its documented default ranking explains all
of it: any cgroup with memory.max scores zero, and a pod cgroup has memory.max
only when every container, init containers included, has a memory limit. The
server had been exposed by its init container, not by its class. See
traps.yaml.

The fix chooses the victim. Immich machine learning has no memory limit - it
is stateless and the largest unlimited pod under load - and every other
application pod, init containers included, has one. The server has 3Gi,
requests equal to limits: 2.5Gi was OOM-killed inside its own limit by the
ffmpeg processes of the second import. Its liveness probe waits three
minutes, because on one busy core it answers late without having hung.
Machine learning has two cores. Immich's own job concurrency is lower: smart
search and face detection 1, thumbnails and metadata 2.

A deliberate stress test - the second phone's import plus Smart Search over
every asset, with Sure running - held with available memory between 0.4 and
1.8 GB and no Talos kill after the change. Sure stays on.

Pod memory limits add up to about 2.3 times the node's memory, and requests
now reserve 88% of it; a new service has about 1.3 GiB to fit into.

## Swap is not available without a disk

Talos can make a swap partition (SwapVolumeConfig) with zswap over it, and
kubelet can allow LimitedSwap, but no disk has room: EPHEMERAL takes all
126 GB of the system NVMe, the WD NVMe is one LVM physical volume, and both
HDDs are whole user volumes. The volume group has 23 GB unallocated, but Talos
swaps only onto partitions. A logical volume switched on by a privileged pod
would work outside Talos's knowledge; it was set aside unless memory is still
short once machine learning is off the node.

## Left open

- Done later the same day: the control plane got memory limits in the Talos
  patch (applied by the owner with terraform apply after validate, dry-run and
  plan), and Cilium and OpenEBS got them on every container. Immich machine
  learning is now the only pod Talos's OOM controller can pick. Cilium's
  restart left `*.home` unanswered for under a minute while 192.168.8.15 was
  announced again. The watch cache was left alone: most of kube-apiserver's
  memory is growth over uptime, and no saving could be estimated.
- kube-apiserver fell from about 1.45 GiB to 0.86 GiB after the node's reboot
  that day. It was 0.83 GiB after the 03:58 kill as well, so this looks like
  growth over uptime rather than anything the static address changed; worth
  measuring again in a few days.
- Sure's Sidekiq worker had been started with `command`, which skipped the
  entrypoint that preloads jemalloc; it now uses `args`. The saving is not
  measured yet.
- 01-talos/README.md described the NVMe as apps and cache volumes; fixed.
  Its context name, admin@beelink, is right for the kubeconfig Terraform
  generates; the local one had been renamed to beelink by hand.
- Moving machine learning to Proxmox remains the largest saving, once
  Proxmox stops losing power.
