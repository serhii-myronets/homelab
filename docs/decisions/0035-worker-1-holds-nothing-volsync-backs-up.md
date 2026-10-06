---
id: "0035"
title: worker-1 holds nothing that VolSync backs up
date: 2026-09-30
status: superseded in part by 0046
tags: [worker-1, controlplane, volsync, storage, scheduling, memory]
hosts: [core, worker-1]
---

# worker-1 holds nothing that VolSync backs up

> worker-1 has had no taint since 2026-10-05 (0046), so the movers could
> now run there. The division below still stands until a move is decided.

controlplane's memory is reserved to 89% by requests, and worker-1 has most of
its 7.6 GB free, so services were weighed for moving. Everything that reads
the HDDs stays: they are controlplane's alone, and a pod on worker-1 could
reach them only over the network. Of the rest, Sure was the largest - 672 Mi
of requests.

It stays on controlplane, and so does every service with a `backed-up-volume`
claim. VolSync's movers take no tolerations, in 0.16.0, the newest release, or
before, so on a node with worker-1's taint they cannot start, and a claim
there could be neither restored from R2 nor backed up. The division is
therefore:

- **controlplane** - state and the HDDs: every claim VolSync backs up, the
  databases, the photographs, the media.
- **worker-1** - compute and data that can be lost or remade: FlareSolverr,
  Immich's machine learning and its model cache, metrics and logs, and copies
  of what controlplane holds, which are backups themselves.

## Rejected

- **Namespace-wide tolerations**, through the PodNodeSelector and
  PodTolerationRestriction admission plugins: a namespace annotated for
  worker-1 would put every pod in it there, movers included. Planned, dry-run
  on 2026-09-30, and dropped before it was applied - a change to the control
  plane, on `scheduler.alpha` annotations, to carry one service, whose
  Postgres would then run on a Celeron against an SSD held at half its link
  speed. The memory it would free is not where controlplane runs short:
  that is machine learning's 2-3 GiB peaks.
- **PreferNoSchedule instead of the taint**, which movers would pass: it
  lets anything overflow onto worker-1 when controlplane is full, which is
  what the taint is there to prevent.
- **A mutating policy engine** such as Kyverno, adding the toleration to
  movers: a new component with its own memory, to answer one field VolSync
  lacks.

Revisit if VolSync gains mover tolerations.
