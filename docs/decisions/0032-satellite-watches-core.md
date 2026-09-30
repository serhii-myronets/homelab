---
id: "0032"
title: satellite becomes a second Talos cluster that watches core
date: 2026-09-29
status: accepted
tags: [satellite, talos, observability, backup, gitops, naming]
hosts: [satellite, core]
---

# satellite becomes a second Talos cluster that watches core

The old OpenMediaVault box serves nothing since core took its services. It
stays, rebuilt as its own single-node Talos cluster, `satellite`, with a job
no machine in the house can do from inside core: watch core and keep copies of
what core backs up. Nothing may depend on it; core runs the same without it.

What it is for, in the order it is likely to be built:

- The metric and log stores for every cluster - VictoriaMetrics,
  VictoriaLogs, Grafana with its dashboards in Git, vmalert and Alertmanager.
  core and the lab ship to it through a light agent each; history survives a
  core that went down, which is exactly when it is wanted. Alertmanager's
  always-firing Watchdog pinging an outside dead-man's switch is what reports
  satellite itself, or the power, going away (0008).
- Gatus in place of Uptime Kuma, whose monitors live in its database and which
  falls over with core (0022).
- A pull copy of Immich's originals, and a `restic copy` of every repository in
  R2 under a read-only token, so core holding write keys to R2 cannot erase
  every copy; plus scheduled restores that prove the backups read back.
- A canary for upgrades: Talos, Kubernetes and Flux move here before core.
- Possibly Immich's machine learning, which is core's largest memory spike and
  runs on this Celeron's iGPU in reports - to be tried beside core's before
  moving, since it would make a part of core depend on satellite.

## Rejected

- Donating its disks: Proxmox has 1.6 TB free, and core already has a 128 GB
  system disk.
- A worker in core's cluster: more memory for stateless pods only, since
  core's volumes are node-local; and its copies would then be within reach of
  whoever holds core.
- Joining Proxmox as a two-node Proxmox cluster: no quorum without a third
  vote, nowhere to migrate to between an i9 with 62 GB and a Celeron with
  7.6 GB, and it would put satellite in the lab.
- Debian with k3s, NixOS, or Portainer staying: each leaves part of the
  machine outside Git or adds a second way of running Kubernetes. The owner
  wants everything on it in GitOps, and Talos with Terraform is already how
  core is built. Talos has no Wi-Fi; the box is wired.
- The router with the T7 as the copy target: the boundary with the internet,
  configured only through its UI, and wiped once already.
- Switching it off: honest if only a copy were wanted, since R2 already holds
  one off-site; the observer role is what makes it worth a cluster.

## As built in satellite/01-talos

Its own secrets, never core's - shared ones would let either cluster's
credentials into the other. The same image schematic as core. A static
192.168.8.20 and the fixed hostname `satellite`: the LAN is laid out in tens,
core in .10-.19 with its load balancer at .15-.19, satellite in .20-.29. The
system disk is chosen by serial, because `sda` and `sdb` swap between boots.
Swap behind zswap and the EPHEMERAL cap are set before the first boot, which
on core took a wipe.

The same platform as core, not a lighter one. Cilium rather than flannel,
although it costs about 400 MiB of the 7.6 GB: a canary must run what core
runs to find its problems first, and Grafana or Gatus are then exposed through
the same Gateway and HTTPRoutes. The whole ORICO is one LVM volume group under
OpenEBS LVM LocalPV rather than two fixed Talos volumes: each claim is a thin
logical volume with a hard size, which keeps logs from taking the backups'
room without guessing the split in advance. Thin pools let claims add up to
more than the disk, so they must not.
