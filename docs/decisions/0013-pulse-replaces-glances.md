---
id: 0013
title: Pulse replaces Glances as the infrastructure monitor
date: 2026-09-12
status: accepted
tags: [monitoring, pulse, docker, proxmox, homepage]
hosts: [core, proxmox]
---

Use one Pulse server on core, native agents on core and Proxmox, and one Pulse
card in Homepage. This replaces the twelve Glances cards and their two
unauthenticated APIs with one authenticated interface that stores history and
understands Docker and Proxmox workloads.

The server is a Portainer Git stack because it is an ordinary persistent core
service. Agents remain under `tools/` because they measure the host and are
installed by hand. Proxmox can additionally be connected with a read-only API
token for its VM/LXC inventory.

Pulse is deliberately internal-only. Router monitoring, when added, uses
agentless availability checks; no third-party agent is installed on the
internet boundary.
