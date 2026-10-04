---
date: 2026-10-04
title: The Proxmox host's CPU and dashboard, and the lab writing to core's observability
tags: [proxmox, cpu, proxmenux, observability, victoriametrics, vmauth, lab]
hosts: [proxmox, core]
---

# The Proxmox host's CPU and dashboard, and the lab writing to core's observability

One day. Every fact it touches lives in hosts/proxmox.yaml or decisions/;
the lab's own side is in its repository's session note.

## The host

ProxMenux still showed the workers' 100 GB data disks a day after Terraform
had removed them. Its Monitor caches each guest's configuration in memory
with no expiry and refreshes it only on its own actions or a guest's start;
a restart of proxmenux-monitor cleared it. The control planes' 100% memory
there was Proxmox's own figure for VMs without a balloon device - the lab's
note tells that half.

The CPU ran at 74 °C under light load. The governor was already powersave;
the energy-performance preference was the default, balance_performance.
Measured a minute each with the lab running: 13 W and 61 °C, 9 W and 56 °C
at balance_power, 8 W and 55 °C at power, which also caps the boost under
real load. cpu-powersave.service now sets balance_power after the governor.

## Observability

The lab needed metrics and logs, and the owner asked where the stack
belongs. One stack, on core (0040): the lab runs only the agents and writes
through ingest.home to a vmauth that admits the lab's token on the two write
paths alone - checked from the Mac: 401 without the token, refused on query,
delete and log reads with it. Core's dashboards got a cluster selector,
VMSingle 1.5 Gi of memory for the second cluster's series, its logs a
cluster field, and both stores a month's retention.

## Infisical's identities

Core's External Secrets turned out to log in as `talos-cluster`, a member of
core's project, while `homelab` - the organization admin the notes had taken
for core's - was used by nothing since the lab got its own. A search printed
talos-cluster's client secret into the session, so the identities were
remade: `core`, Viewer on core's project and nothing in the organization,
its credential in initial-secret.yaml and the copy at /system/infisical;
talos-cluster and homelab deleted. All 21 ExternalSecrets synced again with
only `core` left. Terraform logs in as the owner (the lab's decisions/0009).

Still open:
- Whether the Proxmox console's websocket passes through the Gateway on
  proxmox.home; untested.
- Immich's originals outside the house - R2.
- Alerting (0008): a Telegram bot and a healthchecks.io account, then
  Gatus's alerting block and its heartbeat.
- core/01-talos: its R2 backend needs the parameters Terraform 1.16 asks for
  before its next init, and its README still writes the kubeconfig with `>`.
