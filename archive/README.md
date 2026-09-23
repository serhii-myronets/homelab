# Turned off, kept whole

Setups that ran on the Beelink and were switched off because nothing needed
them yet. Their historical Argo manifests are retained unchanged as reference.

Flux reads `../core-talos/03-gitops/apps/`, not this directory, and this
sits outside `core-talos/` entirely because nothing here is deployed. Moving an archived Argo Application
into the active tree does not restore it: convert it to a Flux Kustomization
and, for charts, a HelmRepository/HelmRelease first. Preserve chart values,
secret references, storage protection and restore settings during conversion.
Renovate excludes these archived definitions, so review their versions before
reactivating them.

## database — CloudNativePG, the Barman Cloud plugin and a shared Postgres

Worked on 2026-09-19: one instance of PostgreSQL 18.6 on the `lvm` class, WAL
archived continuously to Cloudflare R2 and a base backup at 04:00 with 30 day
retention, under `s3://homelab-backups/cnpg`, series `postgres-v2`. It was
built for Paperless and switched off before Paperless existed: the database
held 7.8 MB and no table of its own. See
[`decisions/0019`](../../../docs/decisions/0019-beelink-backups-to-r2.md).

To restore it, move its `components/` into the corresponding active
component directory and convert its archived `applications/` into Flux
resources under `apps/`. Validate the build before committing.

The Cluster carries `bootstrap.recovery` from R2, so a cluster recreated this
way restores itself from the archive rather than starting empty, and then
keeps writing to the same series. That is safe only while the cluster it
recovers from is gone. Its one secret, the R2 key pair, is read from Infisical
at `/backups/R2`; nothing here has to be pasted back by hand.

## observability — the VictoriaMetrics k8s stack

Ran on 2026-09-20 for an evening: victoria-metrics-k8s-stack 0.93.0, with
VMSingle keeping a month on a 20Gi `lvm` claim, vmagent over 17 targets,
vmalert and Alertmanager carrying the chart's rules, Grafana open without a
sign-in at `grafana.home`, kube-state-metrics and node-exporter. It settled
at 1006Mi and 82 millicores and grew about 382MiB a day.

It was replaced by Pulse rather than outgrown. Nothing here was wrong: Pulse
watches Proxmox and Docker as well as this cluster, and sends its own alerts,
which is the open half of
[`decisions/0008`](../../../docs/decisions/0008-nothing-tells-anyone-when-something-breaks.md)
that this stack never closed - its Alertmanager had rules and no recipient.
What is given up is a month of history against seven days, and arbitrary
queries against fixed dashboards.

To restore it, move its `components/` into the corresponding active
component directory and convert its archived `applications/` into Flux
resources under `apps/`. Validate the build before committing.

Then add `grafana.home` back to the `home-ca` certificate. Four of its
lessons outlived it and stayed in
[`traps.yaml`](../../../docs/traps.yaml): a chart that mints a secret while
it renders, a release name that overflows a label, the apiserver paying for
its own metrics, and Talos keeping the controller manager and the scheduler
to itself.

## pulse — the Pulse hub and its Kubernetes agent

Ran on 2026-09-20 for about an hour: pulse/pulse 6.4.1, the server on a
10Gi `lvm` claim behind `pulse.home` and `pulse.serhii.link`, with an agent
reading the cluster in Kubernetes mode. It settled at 81Mi, an order of
magnitude under the stack it replaced, and its CPU sat higher than that
suggests - 150 to 400 millicores on the server.

It went for what it is rather than what it did: open core. The Community
edition is MIT and carries everything this house needed, alerts included,
but remote access, the mobile application, longer history and the
investigation features are a separate commercial product built from
private sources, and that boundary is not ours to rely on.

To restore it, move its `components/` into the corresponding active
component directory and convert its archived `applications/` into Flux
resources under `apps/`. Validate the build before committing.

Then add `pulse.home` back to the `home-ca` certificate. Its agent token
is still in Infisical at `/pulse/AGENT_TOKEN`, and a new server will not
accept it - mint another after the administrator account exists. Two of
its lessons stayed in [`traps.yaml`](../../../docs/traps.yaml): a probe
that cannot reach what it probes, and what happens when an operator and
its work are deleted in one move.

## paperless — Paperless-ngx document archive

Trialled on 2026-09-22 with a fresh, empty database. It was stopped that day:
Google Drive is sufficient for the household documents now, and an unused OCR
service was not worth its roughly 700 MiB of RAM. Flux deletes the empty 20 GiB
claim and its dynamically provisioned volume with the application.

The manifests are preserved in `paperless/`. To restore it, move that directory
back to `core-talos/03-gitops/apps/services/`, add its `ks.yaml` to the root
apps Kustomization, and add `paperless.home` to the local certificate. Validate
the build before committing. Its Infisical entries remain at `/paperless`.
