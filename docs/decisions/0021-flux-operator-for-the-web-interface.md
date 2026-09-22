---
id: "0021"
title: The Flux Operator installs Flux, for its web interface
date: 2026-09-22
status: accepted
tags: [flux, gitops, ui, resources]
hosts: [beelink]
---

# The Flux Operator installs Flux, for its web interface

Install Flux through the Flux Operator and a `FluxInstance` resource rather
than through the community `flux2` Helm chart. This changes how Flux is
installed, not the choice of Flux made in
[0020](0020-flux-for-gitops.md).

The reason is the operator's web interface and nothing else. It is served by
the operator's own pod on port 9080, so it is not a second deployment: the
whole cost of having it is the cost of the operator. Measured after
reconciliation settled, the operator with the interface is 95 MiB, and Flux
in total went from 112 MiB across three controllers to 210 MiB across five -
the operator, the same three controllers, and notification-controller, which
came back in the same change because the `FluxInstance` is where the component
list now lives. Argo CD, for comparison, was 462 MiB.

This reverses the reasoning recorded earlier the same day, when the operator
was rejected as an extra pod bought for fleet features - upgrades across
clusters, sharding, preview environments, multitenancy - that a single node
cannot use. That part still holds and none of it is enabled. What was wrong
was treating the interface as already covered by Headlamp. Headlamp is a
general cluster console with a Flux plugin; this is a view built for
reconciliation, and it comes with an MCP server that lets an assistant read
Flux state directly rather than parsing `kubectl`.

Everything in `controlplaneio-fluxcd` is AGPL-3.0, including the interface.
ControlPlane sells an enterprise distribution with CVE SLAs and support, which
is a different product and not installed here. This matters because
[0013](0013-pulse-replaces-glances.md) was reversed for exactly the opposite
reason - features behind a paywall - and that objection does not apply.

The interface is anonymous on `flux.home` and, behind Cloudflare Access, on
`flux.serhii.link`. Without authentication it is read-only and cannot read
Secrets or ConfigMaps, which is a narrower grant than `headlamp.home` already
has on the same LAN.

Two settings had to be turned off to make it reachable at all, both recorded
in [`traps.yaml`](../traps.yaml): the operator's multi-tenancy network policies
and the chart's own policy for the web port. Neither admits traffic from the
Cilium Gateway, whose Envoy runs on the host rather than as a pod.

`spec.sync` is deliberately unset. The `GitRepository` and root `Kustomization`
that point at this repository stay in `03-gitops/flux.yaml`, so the operator
manages the controllers and the desired state stays where it was.
