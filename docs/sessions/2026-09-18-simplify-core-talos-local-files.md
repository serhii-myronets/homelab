---
date: 2026-09-18
title: Simplify local files for the ME Pro bootstrap
tags: [talos, terraform, bootstrap, secrets]
---

The cluster had been installed and bootstrapped successfully. Talos v1.14.1
answered with RBAC enabled, and the Terraform state contained the machine
configuration, bootstrap and kubeconfig resources.

Removed the plan helper and generated plan, rendered machine config and local
copies of client configs. The active Talos and Kubernetes configs already live
in their standard user paths with the `me-pro` contexts.

Moved the local state, its backup and the original secrets bundle directly
under `core-talos/bootstrap/`. They remain plaintext and ignored by Git. The
explicit local backend was removed, restoring Terraform's default state path.
