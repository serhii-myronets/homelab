# homelab

Three machines at home, in two halves.

**[`core/`](core/)** is executable — the Docker stacks, the bootstrap and the
backup job for the OpenMediaVault box at `192.168.8.100`. Portainer deploys
every stack in it straight from this repository. Start at
[`core/README.md`](core/README.md) to build the machine from nothing or to
restore it.

**[`docs/`](docs/)** is descriptive — what all three machines are, how they are
wired together, and what has already gone wrong. Facts as YAML, one file per
machine, each verified against the live host; reasoning as Markdown. Nothing in
it is deployed anywhere. Start at [`docs/index.yaml`](docs/index.yaml), which
maps a question to the one file that answers it.

Changing one half should rarely mean changing the other.

| | | Deployed from here |
|---|---|---|
| the OpenMediaVault box | services, files, backups — the one nothing else may depend on | yes, out of `core/` |
| the Proxmox host | built and destroyed on purpose: Talos, Terraform | no |
| the router | routing, DNS, firewall, VPN — the boundary with the internet | no, and never over ssh |

[`AGENTS.md`](AGENTS.md) is the entry point for coding agents.
