---
id: "0050"
title: Traces from the LAN come through the Gateway as otlp.home, traces only
date: 2026-11-18
status: accepted
tags: [observability, traces, tempo, opentelemetry, gateway]
hosts: [core]
---

# Traces from the LAN come through the Gateway as otlp.home, traces only

The Appraisal Workbench (the owner's application, its own repository) runs
on the Mac, not in a cluster, and is instrumented with OpenTelemetry: each
preparation of a report is a trace, its steps spans. Its spans go to Tempo
the way a pod's do, through the collector (0048), which is reached from
outside the cluster by an HTTPRoute on core's Gateway:
`https://otlp.home/v1/traces` to the collector's OTLP HTTP port 4318
(`core/03-gitops/apps/system/observability/app/otlp.yaml`), with `otlp.home`
in the Gateway's certificate.

Only the traces path is routed. Local only, like grafana.home: nothing of it
is offered under serhii.link.

## Rejected

- **The collector's ports on the hosts.** 0048 keeps nothing open on the
  nodes; the Gateway is where local names already come in, with TLS from
  home-ca.
- **A token in front of it, as for ingest.home (0040).** ingest.home lets the
  lab write metrics into core's store; a token there limits another cluster.
  This one serves one device on the LAN and carries traces only, which Tempo
  drops after a week; the collector has no auth extension configured to
  check one. Revisit if a second sender appears.
- **Sending straight to Tempo.** Rejected in 0048 for every sender: it skips
  the collector's queue and ties the sender to the store.
- **Running the application in the cluster now.** It runs its agent under
  the owner's Claude login and a macOS sandbox, and changes many times a
  day; it moves when its functionality settles, with its files to R2.
