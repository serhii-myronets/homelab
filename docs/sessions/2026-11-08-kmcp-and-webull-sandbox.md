---
date: 2026-11-08
title: kmcp on core, and Webull's MCP server waiting for sandbox keys
tags: [mcp, kmcp, agentgateway, webull, trading, agents]
hosts: [core]
---

# kmcp on core, and Webull's MCP server waiting for sandbox keys

The owner wants an advisor to be able to buy and sell through a Telegram
chat, by way of an AI agent calling a broker over MCP. Most of the session
was talk about the shape of it, settled only as far as this:

- Whatever can be fooled (the model) or stolen (a Telegram account) may at
  most propose an order. Execution sits behind code with limits and a
  confirmation from a person.
- Webull rather than Interactive Brokers for a first try: Webull gives an
  individual an App Key and Secret and publishes its own MCP server, while
  IBKR wants the IB Gateway Java process, re-approved on the phone about
  weekly, or OAuth that its documentation offers only to advisors and
  institutions.
- The pieces from Solo/kagent: kmcp runs MCP servers from an `MCPServer`
  resource; agentgateway fronts them (tool filtering, audit); kagent hosts
  agents and is called over A2A - none of them listens to Telegram, so a
  bridge is always our own code.

## Done

kmcp 0.4.0 runs on core in `kmcp-system`, its CRD and controller as two
HelmReleases from `oci://ghcr.io/kagent-dev/kmcp/helm`, the first OCI
HelmRepository in `helm-repositories.yaml`. kagent's chart carries the same
controller as a subchart; installing kagent later means `kmcp.enabled: false`.

## Open

`apps/services/webull-mcp/` is written and passes a server-side dry run, but
is not listed in `apps/kustomization.yaml`: the owner has a Webull US account
and no API keys yet. To bring it up:

1. Register at developer.webull.com and generate sandbox (UAT) keys.
2. Put them in Infisical at `/services/webull-mcp/WEBULL_APP_KEY` and
   `/services/webull-mcp/WEBULL_APP_SECRET`.
3. Add `services/webull-mcp/ks.yaml` to `apps/kustomization.yaml`, diff, push.
4. If the server asks for 2FA, run its `auth` inside the pod and approve in
   the Webull app; the token lands on the `data` claim for 15 days.
5. Port-forward port 3000 and point an MCP client at `http://localhost:3000/mcp`.

Untested until then: the uv image as uid 1000, and whether the sandbox needs
hosts beyond the two in the CiliumNetworkPolicy - the first Cilium policy on
core.
