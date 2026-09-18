---
date: 2026-09-17
title: Prepare the ME Pro Talos repository layout
tags: [talos, me-pro, bootstrap]
---

Prepared local cluster generation, without applying configuration to the host.
The owner chose `core-talos/bootstrap/` instead of a tools installer, with
future application directories alongside it. Plaintext credentials remain
in its Git-ignored private directory at the owner's request.

The initial legacy scheduling patch failed strict validation because Talos
1.14 generates separate Kubernetes configuration documents. Replaced it
with a KubeNodeConfig patch removing the control-plane scheduling taint;
generation and strict metal validation then succeeded.

The owner is recabling for a bridge between the two physical LAN ports.
Bridge configuration and address verification remain pending. No install,
bootstrap or reboot was performed. See the bootstrap README for procedure.
