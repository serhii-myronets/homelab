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


The owner subsequently chose Terraform. Imported the same secrets bundle into
an ignored local state, replaced the generator with a plan/validation helper,
and prepared the bridge patch after read-only network verification.
The RC provider's native install/hostname document handling failed CLI
validation. Stable provider 0.11.0 with the v1.13 contract produced a config
accepted by the v1.14.1 CLI. All on_destroy booleans must be explicit in this
provider to avoid a null-value conversion error. The final plan has only the
three initial cluster operations, with no secrets changes. No apply ran.

The owner added the ME Pro reservation in the router UI and reconnected the
uplink cable. Read-only DHCP and Talos API checks confirmed the reserved
address (recorded in hosts/router.yaml) is now active. Updated the Terraform
endpoint and regenerated the plan; installation remains unapplied.
