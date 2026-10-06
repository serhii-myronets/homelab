---
id: "0047"
title: Loki runs beside VictoriaLogs on the same logs, until one is chosen
date: 2026-10-05
status: open
tags: [observability, logs, loki, victorialogs, opentelemetry]
hosts: [core]
---

# Loki runs beside VictoriaLogs on the same logs, until one is chosen

0043 kept VictoriaLogs as the store and rejected Loki as no more of a
standard. That undersold Loki: LogQL is what the field knows, and Grafana's
own log tooling - Logs Drilldown above all, live tail, links from logs to
traces - is built for Loki first. Against it, VictoriaLogs indexes every
word where Loki indexes labels and scans the rest, and runs as one binary
with almost no configuration.

The owner chose to run both for a while and compare, the month of history
being no concern. The collector writes every line to each
(`core/03-gitops/apps/system/observability/app/otel-collector.yaml`); Loki
(`loki.yaml` beside it) is one process on worker-1, its chunks and index on
a 20 GiB volume, a month kept, the chart's caches, gateway, canary and
MinIO off. Grafana has both as datasources. The lab still writes to
VictoriaLogs alone.

Loki takes OTLP itself and made labels of the cluster, namespace, pod,
container and workload names; everything else is structured metadata. On
2026-10-05, minutes in, it had 75 lines of a minute against VictoriaLogs'
72 - the window's edges - and held 57 MiB.

## Deciding

Worth comparing after a week or so: memory and disk of each, the time a
search over a few days takes in each - a word, not a label - and which of
Grafana's log views is the one used. Whichever loses goes, with its
datasource and its exporter; if it is VictoriaLogs, the lab moves to the
collector first, and the `lab` VMUser forwards to Loki's OTLP path.
