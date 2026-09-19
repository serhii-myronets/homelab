---
id: "0014"
title: Manage the replacement core bootstrap with Terraform
date: 2026-09-17
status: accepted
tags: [talos, terraform, bootstrap, secrets]
---

# Manage the replacement core bootstrap with Terraform

The owner chose Terraform in `core-talos/talos/` for bare-metal cluster
configuration application, initial bootstrap and client credentials. YAML
patches remain reviewable inputs. Application deployments live separately.

A standalone talosctl generation script was the initial alternative. It was
replaced before installation to track bootstrap state and expose a plan.
Secrets already generated locally are imported rather than recreated.
At the owner's request, plaintext credentials and local state live in an
ignored private directory. Recovery requires a separate copy of that directory.

Provider and configuration contract versions are pinned independently from
the installed OS; see the bootstrap README for the tested combination and
operational procedure. No node installation was authorized by this choice.
