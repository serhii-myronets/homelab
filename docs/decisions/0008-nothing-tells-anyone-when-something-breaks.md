---
id: "0008"
title: Nothing tells anyone when something breaks
status: open
date: 2026-09-06
updated: 2026-09-30
tags: [monitoring, alerting, healthchecks, telegram, risk]
---

# Nothing tells anyone when something breaks

Failures here are quiet. Uptime Kuma on core sees a service stop answering,
but has no notification channel set up, and cannot report core itself going
down (0022). Flux's notification-controller runs with nowhere to send. No
metrics stack runs since observability went back to the archive, so nothing
alerts on memory, disks, the thin pool or a backup that stopped. A disk can
fail, a VolSync source can stop syncing (traps.yaml), and the first sign is
something missing.

## The shape of the fix

One channel and three producers, all declared in Git where they can be:

- **Telegram**, through a bot: gated by a token, and a push is harder to miss
  than mail. The token belongs in Infisical.
- **An outside heartbeat** - healthchecks.io or equivalent - for what nothing
  in the house can report: power, the internet, the router, core's control
  plane. Whatever runs the alerting pings it; silence raises the alarm.
- **Something that watches core from outside core.** The plan is on the
  router: Gatus, or the router's own packages, checking core's names and
  pinging the heartbeat (decisions to come with it; 0007 governs how).
- **In-cluster alerts** when a metrics stack returns: Alertmanager's
  Watchdog to the heartbeat, its rules to Telegram, and Flux's
  notification-controller for failed reconciliations.

## Status

Open. Nothing blocks it but creating the bot and the heartbeat.
