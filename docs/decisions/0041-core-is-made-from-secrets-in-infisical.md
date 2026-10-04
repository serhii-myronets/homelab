---
id: "0041"
title: core is made from its Talos secrets in Infisical, writes its client configurations back, and its External Secrets log in by JWT
date: 2026-10-04
status: accepted
tags: [talos, terraform, infisical, external-secrets, jwt, secrets, kubeconfig]
hosts: [core]
amends: ["0037"]
---

# core is made from its Talos secrets in Infisical, writes its client configurations back, and its External Secrets log in by JWT

The lab was moved first (its repository's decisions/0010 and 0011); core
followed the same day, the same way, so both clusters are run alike.

**The Talos secrets.** Since 0037 a copy of `secrets.yaml` was in Infisical,
`/system/talos/SECRETS_YAML`, while Terraform used the copy imported into its
state. Terraform now reads the Infisical copy on every run - checked equal,
field by field, before the switch - and `talos_machine_secrets.cluster` was
dropped from the state, not destroyed. The plan changed neither node's
configuration; the apply re-sent both unchanged and neither rebooted.

**The client configurations.** Made from the secrets on each run by the
Talos provider's ephemeral resources (0.11.0 has them), valid as long as the
CAs and never kept in the state; the nodes take the client configuration
write-only. An apply writes them to `/system/talos/TALOSCONFIG` and
`KUBECONFIG`, and `scripts/contexts.sh` - the lab's script - merges them
into the Mac's `~/.talos/config` and `~/.kube/config`, as the context
`core` in each - Talos's `admin@core` renamed for Kubernetes. The Talos context left over as `beelink`, from when the
cluster had that name, was removed with the stale `satellite`.

**External Secrets.** It logged in as the identity `core` with a Universal
Auth client secret placed by hand, `core/02-platform/prepare-hook/
initial-secret.yaml`, with a copy at `/system/infisical`. Now `core` has
static JWT auth with the public half of the cluster's ServiceAccount key,
taken from its JWKS and given by hand once - the key comes from the Talos
secrets and does not change - and External Secrets sends a long-lived token
of `external-secrets/infisical`, which Kubernetes itself fills into a Secret
(`core/03-gitops/apps/system/security/external-secrets`). Universal Auth is
off for `core`; the file and the copy are gone. All 21 ExternalSecrets
synced afterwards.

Not by Terraform: the Infisical provider's `infisical_identity_jwt_auth`
refuses a computed public key (traps.yaml,
infisical-jwt-auth-refuses-a-computed-public-key).

What is accepted is 0037's: the cluster can read its own Talos secrets
through its identity, and now its client configurations beside them.

Rejected: Kubernetes auth in Infisical, which needs Infisical Cloud to reach
the cluster's API, or Infisical's Enterprise Gateway; SOPS for the one
bootstrap secret, which the owner did not want.
