---
id: 0001
title: Portainer deploys the stacks, nothing deploys Portainer
status: accepted
date: 2026-09-06
tags: [portainer, gitops, deployment, bootstrap]
hosts: [core]
---

Four stacks come straight from this repository through Portainer's GitOps.
Portainer itself is brought up by `core/bootstrap.sh` with plain compose.

A self-redeploy that fails halfway would take down the UI that manages every
other stack. Keeping it on the manual path also means that path is exercised
rather than theoretical — it is the same command the bootstrap uses.

Its stack definitions live in Portainer's database rather than in git, which
looked like a gap until the database turned out to sit inside `docker/data`
and therefore inside the backup. They survive a rebuild and need one **Deploy**
click each; Portainer does not redeploy stacks on startup.
