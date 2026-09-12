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

The server is an ordinary persistent Docker Compose service on core. It is
currently started from the host checkout rather than reconciled by Portainer.
Agents remain under `tools/` because they measure the host and are installed
by hand. Proxmox is additionally connected using a privilege-separated
`PVEAuditor` API token for its VM/LXC inventory.

Pulse is deliberately internal-only. Router monitoring, when added, uses
agentless availability checks; no third-party agent is installed on the
internet boundary.
