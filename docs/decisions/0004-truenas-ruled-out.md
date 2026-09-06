---
id: 0004
title: TrueNAS SCALE ruled out on hardware
status: rejected
date: 2026-09-06
tags: [os, truenas, zfs, hardware]
hosts: [core]
---

Its minimum is 8 GB of RAM against the NAS's 7.6 GB, and TrueNAS does not
recommend ZFS on a single disk without redundancy, which is exactly the
situation here.

It is also a larger appliance than OMV with a less accessible configuration, so
it moves away from keeping things in git rather than towards it.

NixOS is the alternative that would genuinely serve the goal — the whole
machine in one repository, atomic rollback through generations, and
[compose2nix](https://github.com/aksiksi/compose2nix) to carry the existing
compose files across. It is a project rather than a weekend, and worth starting
when it is wanted as a project, not as a fix for a problem that no longer
exists.
