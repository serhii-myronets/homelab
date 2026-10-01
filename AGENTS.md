# Working in this repository

| | | Deployed from here |
|---|---|---|
| **core** | the cluster where the services and their data live — everything depends on it. Nodes `controlplane` (a Beelink ME Pro, 192.168.8.10) and `worker-1` (the old OpenMediaVault box, .11, tainted) | yes, out of `core/` |
| **proxmox** | the lab, built and destroyed on purpose — unreachable since the router's reflash | no |
| **router** | the boundary with the internet — DNS, DHCP, firewall, WireGuard | only Gatus, by `router/gatus/install.sh` ([0036](docs/decisions/0036-gatus-on-the-router.md)); nothing else, and never its settings over ssh |

Machines are named for their role, not their hardware. Older commits say
`beelink` for the cluster, `core-talos/` for its directory, and `core` or
`satellite` for the box that is now `worker-1`.

`core/` is *executable* — Talos configuration, the platform bootstrap and the
Flux tree. `docs/` is *descriptive* — what every machine is, why, and what has
already gone wrong. `archive/` holds setups switched off but kept whole;
nothing reads it.

**Read [`docs/index.yaml`](docs/index.yaml) first.** It maps a question to the
one file that answers it. Before debugging anything that should work, check
[`docs/traps.yaml`](docs/traps.yaml).

| Path | |
|---|---|
| `core/01-talos/` | Terraform for both nodes; state, `secrets.yaml` and generated configs are local and ignored |
| `core/02-platform/` | Helmfile bootstrap, applied by hand |
| `core/03-gitops/` | everything Flux reconciles |
| `router/gatus/` | the house's watcher on the router; `install.sh` from the Mac delivers every change |
| `docs/` | facts, decisions, the last session |
| `archive/` | switched-off setups, with how to bring each back |

`core/README.md` and the READMEs under it are the operational manual; a
procedure lives in one of them, never in two.

## Access

The nodes have no shell. `kubectl --context admin@core`; `talosctl -n
192.168.8.10` for controlplane, `-n 192.168.8.11 -e 192.168.8.10` for
worker-1. Both configs come from `terraform output` in `core/01-talos`,
contexts included. The router takes `ssh root@192.168.8.1` with
`~/.ssh/id_ed25519` — read-only, see the rules.

## Rules

**Verify before writing a fact down.** Facts come from the live host, not from
memory or another file here. Stale claims that read as true are the errors
this repository has paid for most.

**A fact belongs in exactly one file.** Link to it rather than restate it.
What the manifests say — images, versions, resources — is not repeated in
`docs/`.

**Never change the router over ssh.** GL.iNet's firmware regenerates its uci
from its own state. Read facts, write them to `docs/hosts/router.yaml`, and
describe fixes as UI steps — [`decisions/0007`](docs/decisions/0007-router-config-is-not-ours-to-edit.md).
The one exception is `router/gatus/install.sh`, which writes only Gatus's own
files — [`decisions/0036`](docs/decisions/0036-gatus-on-the-router.md).

**Ask before anything stateful.** Deleting data or volumes, wiping or
resetting a node, rebooting a host: the owner's call, not a step in a plan.

**See the change before making it.** `flux diff kustomization <name> --path
<dir>` before pushing a Flux change. `talosctl validate --strict`, then
`apply-config --dry-run`, before a Talos change — it says whether the node
reboots. Terraform: `plan -out=<file>`, read it, then apply that file.

**Moving anything under `core/` reaches off the repository.** Every Flux
Kustomization stores its path, and the root in `03-gitops/flux.yaml` is
applied by hand. Ignored files — Terraform state, `secrets.yaml` — move with
their directory and their `.gitignore` lines.

**Never print a secret.** Filter `crt|key|secret|token` out of machine
configs and Terraform state; read Infisical values into variables, not onto
the screen.

**Commits carry one author.** No `Co-Authored-By`, no "Generated with", no
agent named in a commit, tag or pull request. Write about the change.

**Commit and push completed changes**, staged by path, without asking again.

**Record what you learn.** A failure mode goes in `docs/traps.yaml` while it
can still happen; a choice with a rejected alternative in `docs/decisions/`;
the narrative of the session in `docs/sessions/`, replacing the previous one —
git keeps the rest.

## The shell

zsh. A variable named `path` rewrites `PATH`; a command held in a variable
is not split into words — call it directly or through a function. YAML under
`docs/` must parse and its front matter carry `tags`.

Comments earn their place by saying something the code does not.
