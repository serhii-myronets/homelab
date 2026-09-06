# docs

Facts are YAML, verified against the live host. Reasoning is Markdown with YAML
front matter. Every fact lives in exactly one file.

**[`index.yaml`](index.yaml) is the entry point** — it maps a question to the
file that answers it, so a lookup costs one read rather than a search.

| | |
|---|---|
| [`hosts/`](hosts/) | one file per machine |
| [`network.yaml`](network.yaml) | subnets, DNS, TLS, what can reach what |
| [`services.yaml`](services.yaml) | the stacks in `../core/`, their routes and options |
| [`backups.yaml`](backups.yaml) | repositories, coverage, gaps |
| [`traps.yaml`](traps.yaml) | failures already paid for once — read before debugging |
| [`decisions/`](decisions/) | why things are this way, and what is still open |
| [`sessions/`](sessions/) | how they got this way; read the newest before starting |
