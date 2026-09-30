# Working in this repository

Four machines:

| | | Deployed from here |
|---|---|---|
| **core** | where the services and their data live — everything depends on it; Talos on the Beelink | yes, out of `core/` |
| **satellite** | watches core and keeps copies — nothing may depend on it; the old OpenMediaVault box, to be rebuilt on Talos | not yet |
| **proxmox** | built and destroyed on purpose — Talos, Terraform | no — only a `tools/` installer, by hand |
| **router** | the boundary with the internet — routing, DNS, firewall, VPN | no, and never over ssh |

Machines are named for their role, not their hardware. Until 2026-09-29
`core` meant the OpenMediaVault box, now `satellite`, and the Talos cluster
was `beelink` in `core-talos/`; sessions and decisions from before then use
the old names.

The repository has two halves and the split is the point. `core/` is
*executable*: Talos configuration, the platform bootstrap and the Flux tree,
deployed onto one cluster. `docs/` is *descriptive*: what every machine is,
why, and what has already gone wrong. Changing one should rarely mean changing
the other. `tools/` is the exception both halves needed: installers run by
hand on a host nothing deploys to, reconciled by nobody.

**Read [`docs/index.yaml`](docs/index.yaml) first.** It maps a question to the
one file that answers it, so a lookup costs one read rather than a search.
Before debugging anything that should work, check
[`docs/traps.yaml`](docs/traps.yaml) — it lists failures already paid for once.

| Path | |
|---|---|
| `core/01-talos/` | Terraform for the node; its state and `secrets.yaml` are local and ignored |
| `core/02-platform/` | Helmfile bootstrap, applied by hand |
| `core/03-gitops/` | everything Flux reconciles |
| `tools/<name>/` | run by hand on a host; not a stack — see decisions/0011 |
| `docs/` | every fact, decision and session; `index.yaml` routes |
| `archive/` | setups switched off but kept whole; nothing reconciles it |

Each half carries its own README: the root one describes the repository,
`core/README.md` and the READMEs under it are the operational manual, `docs/README.md` indexes the facts,
and a `tools/<name>/README.md` covers only how to run that one installer.
A procedure belongs in one of those, never in two.

## Access

core has no shell: `talosctl -n 192.168.8.10` and `kubectl`. The rest take
the key at `~/.ssh/id_ed25519`:

```bash
ssh root@192.168.8.100   # satellite, until it is rebuilt on Talos
ssh root@10.1.1.100      # proxmox
ssh root@192.168.8.1     # router — read-only, see rules
```

`proxmox` also answers unauthenticated on `http://10.1.1.100:8008/api/*`
(ProxMenux Monitor) — hardware and guest facts without a login.

## Rules

**Verify before writing a fact down.** Both documentation errors found on
2026-09-06 were stale claims that read as true. Facts come from the live host,
not from memory or from another file in this repo.

**A fact belongs in exactly one file.** If it is already in `docs/`, link to
it. `README.md` is procedures for a human; it must not restate the tables.

**Never change the router over ssh.** GL.iNet's firmware regenerates uci from its
own state, so a change made there can be invisible in its UI or silently
reverted. Gather facts read-only, write them to `docs/hosts/router.yaml`, and
describe fixes as UI steps for a human. See
[`decisions/0007`](docs/decisions/0007-router-config-is-not-ours-to-edit.md).

**Ask before touching anything stateful.** Deleting data, wiping a repository,
rebooting a host and destroying a Proxmox guest are the user's call, not a
step in a plan.

**Moving anything under `core/` has consequences off the repository.** Every
Flux Kustomization stores its path, and the root one in `03-gitops/flux.yaml`
is applied by hand, so the cluster keeps the old path until someone applies it
again. Check with `flux diff kustomization root --path <new>` before pushing,
and move ignored files - Terraform state, `secrets.yaml` - with their
directory and their `.gitignore` lines.

**Commits carry one author.** No `Co-Authored-By` trailer, no "Generated
with" line, no agent named anywhere in a commit message, a tag or a pull
request. The history is the owner's. Write the message about the change, not
about who made it — the 31 trailers stripped on 2026-09-06 said nothing a
reader needed.

**Commit and push completed changes.** After validation, commit the task's
changes and push the current branch without asking again. Stage by path so
unrelated work is not included.

**Record what you learn.** A new failure mode goes in `docs/traps.yaml`; a
choice with a rejected alternative goes in `docs/decisions/`; the narrative of
a working session goes in `docs/sessions/`, including what was tried and
failed.

**Read only the newest session.** Older ones are history — anything from them
that still matters has already graduated into `docs/`, a decision, or a trap.

## Validating

Flux trees: `flux diff kustomization <name> --path <dir>` against the live
cluster. Talos configuration: `talosctl validate --strict`, then an
`apply-config --dry-run`. YAML under `docs/` must parse; front matter must
carry `tags`.

Comments earn their place by saying something the code does not.
