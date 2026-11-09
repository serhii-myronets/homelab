---
date: 2026-11-08
title: kmcp on core, serving Webull's MCP server against the sandbox
tags: [mcp, kmcp, agentgateway, webull, trading, agents]
hosts: [core]
---

# kmcp on core, serving Webull's MCP server against the sandbox

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

Webull's server (`apps/services/webull-mcp/`, package 1.2.6) runs against
the US sandbox. Checked through a port-forward: a session lists 109 tools,
and `get_account_list` returns the sandbox's five accounts. The sandbox asked
for no 2FA, so no token has been written; `WEBULL_TOKEN_DIR` stays for prod.
The uv image runs as uid 1000, and the CiliumNetworkPolicy - the first on
core - lets through all the server needed.

To use it from the Mac:

    kubectl --context core -n webull-mcp port-forward svc/webull-mcp 3000
    claude mcp add --transport http webull-sandbox http://localhost:3000/mcp

Then made read-only: `WEBULL_TOOLSETS` leaves out `trading`, since kmcp's
MCPServer has no way to filter tools itself. That rollout hung on the `data`
claim (traps.yaml, openebs-lvm-mounts-a-volume-into-one-pod-only, now with
the rollout case), and kmcp offers no `Recreate`; the claim was removed with
the owner's agreement, and `/data` is an emptyDir.

## Open

- Prod's 15-day token needs a home that survives the pod - not a claim
  while kmcp writes the Deployment.
- Ordering back on only behind an agentgateway that filters tools and an
  order path with a person's confirmation.
- Nothing yet: the Telegram bridge, the agent, kagent.
