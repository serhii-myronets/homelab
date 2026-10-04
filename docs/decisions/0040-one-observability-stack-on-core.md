---
id: "0040"
title: One observability stack, on core; the lab writes to it with a write-only token
date: 2026-10-04
status: accepted
tags: [observability, victoriametrics, victorialogs, lab, vmauth]
hosts: [core, proxmox]
---

# One observability stack, on core; the lab writes to it with a write-only token

The Proxmox lab needed metrics and logs of its own. It runs the same
`victoria-metrics-k8s-stack` chart as core, cut down to what collects: the
operator, vmagent, vlagent, kube-state-metrics and node-exporter. Its agents
scrape and read inside the lab as core's do inside core, and write to core's
VMSingle and VLSingle instead of stores of their own. Every series carries
`cluster=lab` as an external label, every log line a `cluster` field; core's
logs now carry `cluster=core`, and core's dashboards a cluster selector.

The stores stay on core because they have to outlive what they watch. The
lab is rebuilt as a matter of course - it was destroyed and applied again on
2026-10-04 - and a stack there would lose its history with every rebuild,
just when it is wanted. The house depends on core, so core must not depend
on the lab; the lab depending on core for its monitoring is the right way
round.

## The way in

The lab cannot reach core's stores, which are cluster-internal services, and
core cannot scrape the lab, whose pods live inside the lab's Cilium network.
So the agents push: `https://ingest.home`, through core's Gateway, to a
vmauth named `ingest` (`core/03-gitops/apps/system/observability/app/ingest.yaml`).
It admits a request only with the lab's token and only on `/api/v1/write`
and `/insert/native`; reads, queries and deletes are refused. A vmagent
queues on its own disk while core is away.

This is an exception to the lab's rule that it holds no credential of core's
(the lab's docs/decisions/0004): the lab holds a token for core. It can only
write, and a stolen one is worth a flood of junk series at worst, never
core's data; it is one VMUser, `lab`, so it can be cut off alone. The token
is in core's Infisical at `/system/observability/LAB_INGEST_TOKEN` and in the
lab's at `/system/observability/INGEST_TOKEN`.

## Rejected

- **A full stack in each cluster.** Two Grafanas to look in, alerts written
  twice, and 2-3 GB of the lab's memory and its own disks for a second copy
  of the stores.
- **The stack in the lab, core writing to it.** Weighed once before, in
  0034, and deferred for the reasons that still hold: Proxmox has lost power
  unsafely more than half the time, and it is the lab.
- **VMSingle published straight onto the LAN.** It has no authentication;
  anyone on the network could read and delete.
