---
id: "0042"
title: core's Headlamp shows the lab too, reading both clusters from kubeconfigs
date: 2026-10-04
status: accepted
tags: [headlamp, lab, kubeconfig, infisical]
hosts: [core, proxmox]
---

# core's Headlamp shows the lab too, reading both clusters from kubeconfigs

One console for both clusters. The lab's Terraform writes its admin
kubeconfig - made from its Talos secrets, the same at every rebuild - into
this project, `/system/headlamp/LAB_KUBECONFIG`; an ExternalSecret brings
it to Headlamp, beside a kubeconfig for core that points at Headlamp's own
ServiceAccount token and CA (`core/03-gitops/apps/system/platform/headlamp`).
Headlamp loads both with `-kubeconfig`, and shows `core` and `lab`.

Headlamp was in in-cluster mode before, handing every visitor its own
ServiceAccount's token. Headlamp 0.45 does that for its own cluster only: in
in-cluster mode a context from a kubeconfig gets no credentials from the
file, and every request to it is refused until a token is pasted in the
browser (backend/cmd/headlamp.go, "no authentication token provided"). So
in-cluster mode is off: from kubeconfigs, each cluster's requests carry the
credentials in its own file, and nothing is asked. Verified on 2026-10-04:
both clusters' nodes listed through headlamp.home with no token.

What the lab gains in exposure is nothing new: headlamp.home has no gate,
so anyone on the LAN can administer the lab through it - as anyone could
already through the lab's anonymous Argo CD. Core holding the lab's admin
credentials is the safe direction; the lab holds nothing of core's
(the lab repository's decisions/0004).

Rejected:
- **The lab's kubeconfig beside the in-cluster context**: a token to paste
  for the lab every session.
- **A second Headlamp in the lab**: two consoles.
