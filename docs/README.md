---
title: Documentation index
tags: [index, docs]
---

# docs

Facts are YAML, verified against the live host. Reasoning is Markdown with YAML
front matter. Every fact lives in exactly one file.

**[`index.yaml`](index.yaml) is the entry point** — it maps a question to the
file that answers it, so a lookup costs one read rather than a search.

| | |
|---|---|
| [`hosts/`](hosts/) | one file per machine |
| [`network.yaml`](network.yaml) | subnets, DNS, TLS, what can reach what |
| [`service-ideas.md`](service-ideas.md) | what to build next |
| [`backups.yaml`](backups.yaml) | repositories, coverage, gaps |
| [`traps.yaml`](traps.yaml) | failures already paid for once — read before debugging |
| [`decisions/`](decisions/) | why things are this way, and what is still open |
| [`sessions/`](sessions/) | the last working session; read it before starting |
