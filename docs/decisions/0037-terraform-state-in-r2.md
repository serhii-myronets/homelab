---
id: "0037"
title: Terraform state in R2 and secrets.yaml in Infisical, where the cluster can read them
date: 2026-10-02
status: accepted
tags: [terraform, talos, r2, infisical, secrets, backup]
hosts: [core]
---

# Terraform state in R2 and secrets.yaml in Infisical, where the cluster can read them

Until now `core/01-talos/terraform.tfstate` and `secrets.yaml` existed only
on the Mac. Without them the cluster could be run but not rebuilt, and
without secrets.yaml an etcd recovery fails, since Talos encrypts Secrets in
etcd with a key from it. One lost or broken Mac would have ended the cluster.

The state now lives in R2 - bucket `homelab-backups`, key
`terraform/core-01-talos.tfstate` - through Terraform's s3 backend and an
`r2` profile in `~/.aws/credentials`, which holds the backup key pair from
Infisical's /system/backups. secrets.yaml is in Infisical at
/system/talos/SECRETS_YAML. Both copies on the Mac stay as they were.

## What was accepted

Both hold the Talos administrator's keys in the clear - the state imports
secrets.yaml. Both now sit where the cluster can read them: its Infisical
identity reads the whole project, and its R2 key opens the whole bucket. A
pod that reached External Secrets could take full control of both nodes.

That pod could already read every service's secrets, the R2 keys and the
restic password - and so read and erase every backup. The cluster is
already the most valuable thing here; the Talos keys add control of the
nodes and persistence, not a different order of risk. For one person's
house that is accepted, rather than a second system to keep.

## Rejected

- **A separate Infisical project and its own R2 bucket and token**, out of
  the cluster's reach. Correct, and twice the things to create and keep for
  a risk already mostly present.
- **A restic copy under a password kept only in a password manager**, run by
  hand after each apply. Out of the cluster's reach too, but it is a step to
  forget, and the state would still live only on the Mac between runs.
- **A wrapper script** feeding the R2 keys to Terraform. A standard AWS
  profile does the same with nothing to maintain.

No lock table: Terraform 1.5 locks S3 state only through DynamoDB, and one
administrator applies.
