---
date: 2026-11-08
title: Webull's MCP servers on core through kmcp and agentgateway, read-only on mcp.home
tags: [mcp, kmcp, agentgateway, gateway-api, webull, trading, agents]
hosts: [core]
---

# Webull's MCP servers on core through kmcp and agentgateway, read-only on mcp.home

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

A second server, `webull-mcp-prod`, reads the real account with the same
toolsets and a Cilium policy of its own for Webull's production hosts. Prod
asks for 2FA: its first call left a PENDING token, and approving on the phone
did not help until `auth` ran in the pod (traps.yaml,
webull-mcp-approval-on-the-phone-is-not-enough). It then listed three
accounts.

## agentgateway in front, on mcp.home

The owner chose a full Gateway API implementation over a standalone proxy.
kgateway turned out to be Envoy only since 2.3; the MCP side is agentgateway's
own controller, now in `apps/system/network/agentgateway/` (1.7.0). Built
against Gateway API 1.7, so the CRDs were applied from 02-platform's prepare
hook first - with the owner's go-ahead, after checking that no served version
Cilium uses changed. Cilium itself (1.20.2 live, 1.20.4 in the repository)
was not touched.

In `webull-mcp`: a Gateway `mcp` of class agentgateway on a ClusterIP Service
(an AgentgatewayParameters overlay - Cluster routability is still
experimental), `/prod` and `/sandbox` routes to the two kmcp Services, and one
AgentgatewayPolicy: an API key from Infisical
(`/services/webull-mcp/MCP_GATEWAY_KEY`) and only tools named get_, search_
or list_ - 81 of 89. Cilium's main-gateway serves `mcp.home` with the home
certificate; the Webull pods accept only the proxy now.

Checked end to end with `curl --resolve`: 401 without or with a wrong key;
with it, both paths list 81 tools, quote AAPL, and refuse create_watchlist
and create_community_post. On the way:

- The first key leaked into this session's output: a zsh loop variable named
  `path` (AGENTS.md warns of it) emptied PATH, and zsh printed the failed
  commands with their headers. Rotated at once; the old key gets 401.
- A wait loop asked the router for mcp.home before external-dns had written
  it, and the NXDOMAIN stuck in the router's cache (traps.yaml,
  a-new-public-name-is-cached-as-missing-twice) - BIND on :5300 already
  answered.
- Test sessions left open OOM-killed the prod server (traps.yaml,
  kmcp-stdio-server-runs-a-process-per-open-session).

## Open

- Prod's token lives in an emptyDir: every new pod needs `auth` and the
  phone again. A home that survives the pod is not a claim while kmcp writes
  the Deployment. The same holds back raising the 512Mi limit.
- Ordering stays off until an order path with a person's confirmation
  exists. The Telegram bridge is set aside for now.
- Cilium 1.20.4 from Renovate is still to be applied with Helmfile.
