---
id: "0046"
title: worker-1 carries no taint; what must stay off it is held by its own constraint
date: 2026-10-05
status: accepted
supersedes: "0035, in part"
tags: [worker-1, controlplane, scheduling, taint, cloudflared, gpu]
hosts: [core, worker-1]
---

# worker-1 carries no taint; what must stay off it is held by its own constraint

worker-1 was tainted `homelab/dedicated=worker-1:NoSchedule` from the day
it joined (0034), so that only what was sent there ran there. Everything
else crowded controlplane - 86% of its CPU and 87% of its memory reserved
by requests on 2026-10-05, against a fifth and a third on worker-1.

The taint is gone. The scheduler places pods on either node, and what must
not land on worker-1 is held off by its own constraint rather than by a
blanket one:

- **Claims** stay with their volume. A bound volume carries its node; a
  new claim on `lvm` can only be placed on controlplane, because the LVM
  driver reports no capacity for it on worker-1 and the scheduler reads
  that capacity. `lvm-worker-1` is bound to worker-1 by its topology.
- **The GPU plugin** is pinned to controlplane by node. worker-1's UHD 600
  makes Immich's face detector find nothing (traps.yaml); with no taint the
  plugin would have offered it to any pod asking for a GPU.
- **What is meant for worker-1** - the observability stack, FlareSolverr,
  Homepage, the backups' rest-server - keeps its node selector.

Nothing moved when the taint went; running pods are not evicted. About 1.3
GiB of requests on controlplane - Flux, cert-manager, External Secrets,
external-dns, Headlamp and the like - can now land on worker-1 whenever
they restart.

That puts more on the older machine, and its loss would take more with it,
until Kubernetes moves the pods after five minutes. cloudflared, which
carries every serhii.link name, therefore runs a replica on each node.

The taint had also kept off worker-1, without saying so, what needs a
control plane node by what it does rather than by a volume: the etcd
backup, which asks its own node's Talos API for a snapshot, failed there
the next morning and is now pinned to the control-plane role. The
`nvme-thinpool` Job, which prepares controlplane's disk by its ID, is
pinned to controlplane too; Flux replaced it to do so, and the rerun found
the pool as it was.

VolSync's movers, which take no tolerations, can now run on worker-1, so
the reason 0035 gave for keeping backed-up claims off it no longer holds.
They stay on controlplane for now; moving one is its own decision.

## How it was done

`registerWithTaints` left worker-1's kubelet configuration in Talos -
`apply-config --dry-run` showed no reboot - and `kubectl taint` removed the
taint from the registered node. The tolerations went from every manifest
but the thin-pool Job, whose pod template cannot change in place.

## Rejected

- **Tolerations added one service at a time**, keeping the taint. Every
  move a deliberate change, but every new service on controlplane by
  default, which is where memory runs short.
- **PreferNoSchedule.** Rejected in 0035 for letting anything overflow onto
  worker-1 when controlplane is full; without the taint the same happens by
  the scheduler's own scoring, and the constraints above are what keep the
  wrong things off.
