# homelab

Home infrastructure: one Talos cluster, `core`, on two machines; a Proxmox lab
built and destroyed on purpose; and a GL.iNet router at the boundary.

**[`core/`](core/)** is executable: Terraform for the Talos nodes
(`01-talos/`), a Helmfile bootstrap for Cilium, External Secrets and the Flux
Operator (`02-platform/`), and everything Flux reconciles (`03-gitops/`).
Start at [`core/README.md`](core/README.md).

**[`docs/`](docs/)** is descriptive: what each machine is, how they are wired
together, why, and what has already gone wrong. Facts as YAML, verified
against the live hosts; reasoning as Markdown. Start at
[`docs/index.yaml`](docs/index.yaml).

**[`archive/`](archive/)** holds setups that worked and were switched off,
kept whole so they can come back; nothing reads it.

[`AGENTS.md`](AGENTS.md) is the entry point for coding agents.
