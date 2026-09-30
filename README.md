# homelab

Home infrastructure: one Talos cluster that runs the services, a lab that is
built and destroyed on purpose, and a router at the boundary.

**[`core/`](core/)** is executable — the cluster where the services and their
data live, Talos on the Beelink ME Pro at `192.168.8.10`. `01-talos/` holds its
Terraform-managed Talos configuration, `02-platform/` installs the initial
Cilium, External Secrets and Flux releases, and `03-gitops/` holds everything
Flux reconciles. Start at [`core/README.md`](core/README.md).

**[`docs/`](docs/)** is descriptive — what all machines are, how they are
wired together, and what has already gone wrong. Facts as YAML, one file per
machine, each verified against the live host; reasoning as Markdown. Nothing in
it is deployed anywhere. Start at [`docs/index.yaml`](docs/index.yaml), which
maps a question to the one file that answers it.

**[`tools/`](tools/)** is executable too, but nothing deploys it. Each
directory installs something on a host by hand, outside any cluster. A rebuilt
host needs its installer run again.

**[`archive/`](archive/)** is neither: setups that worked and were switched
off, kept whole so they can be brought back rather than rebuilt from memory —
among them `core-docker/`, the Docker stacks of the old OpenMediaVault box,
now core's node `worker-1`. Nothing reads it — Flux reconciles `core/03-gitops/apps/` and
stops there — and its README says what each one was and why it went.

Changing one half should rarely mean changing the other. The machines and
their roles are in [`AGENTS.md`](AGENTS.md), which is also the entry point for
coding agents.
