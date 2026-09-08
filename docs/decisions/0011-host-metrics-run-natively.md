---
id: 0011
title: Host metrics run natively under systemd, from tools/ rather than core/
date: 2026-09-07
status: accepted
tags: [monitoring, glances, homepage, systemd]
hosts: [core, proxmox]
---

Homepage needed CPU, memory, disk and temperature for the two machines that
run things. Glances answers all four over one HTTP API, so the question was
only where it should run.

A container on core was the obvious choice and is wrong twice. It measures
the container unless it is handed the host's namespaces, and it covers one
machine — Proxmox is not a Docker host and nothing here deploys onto it. Two
containers, one of them privileged and on a machine this repository does not
deploy to, buys nothing over a systemd unit.

So Glances is installed natively on both hosts by `tools/glances/install.sh`,
as `nobody`, out of a virtualenv, with process collection off and the API
bound to the host's LAN address. It is the first thing in this repository
that is executable but not a Portainer stack, which is why it sits in `tools/`
rather than `core/` — `core/` means "deployed onto core by Portainer", and
this is neither.

The cost is a second deployment path. `core/` reconciles itself from git;
`tools/` does not, and a rebuilt host needs the installer run again by hand.
The README says so. Pulling Proxmox in through ProxMenux's existing
unauthenticated API was considered and rejected: it is one host's own
monitor, and would have left core and Proxmox reading from two different
sources with two different shapes.

Nothing authenticates port 61208 and Homepage is public, so anyone who opens
the dashboard sees both hosts' load. That is accepted for load, temperature
and disk fullness; it is the reason process collection is disabled, since a
process list names what runs and is a much longer answer than a percentage.
