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

## First measurement, 2026-10-06

Twelve hours and 40 minutes of core's logs, the same 91,372 lines in each:

| | Loki | VictoriaLogs |
|---|---|---|
| memory, working set at most | 92 MiB | 190 MiB, the lab's logs too |
| CPU, average over an hour | 13m | 13m |
| bytes stored per line | about 34, chunks only | about 20, over all its data |
| count every line in the window | 0.67 s | 0.02 s |
| a word, `error` as a whole word | no such query - lines only | 0.10 s, 2,137 lines |
| a substring, `(?i)error` | 0.66 s, 3,201 lines | 0.68 s, 3,201 lines |
| one namespace by label | 0.17 s | 0.04 s |

Both are small and quick at this size. VictoriaLogs answers what its word
index covers several times faster; a substring is a full scan in either.
Loki's figures are early - it holds recent chunks in memory and flushes
them over hours.

## Deciding

Worth comparing after a week or so: memory and disk of each, the time a
search over a few days takes in each - a word, not a label - and which of
Grafana's log views is the one used. Whichever loses goes, with its
datasource and its exporter; if it is VictoriaLogs, the lab moves to the
collector first, and the `lab` VMUser forwards to Loki's OTLP path.
