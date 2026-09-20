# Turned off, kept whole

Setups that ran on the Beelink and were switched off because nothing needed
them yet. The files are exactly as they were when they worked: no path inside
them was rewritten, so bringing one back is a move, not an edit.

Argo does not see this directory. The root Application reads only
`../applications/`, so a setup goes dark the moment it is moved here and
comes back when it is moved out. Renovate is equally blind to it — its
managers match `components/` and `applications/` — so an archived setup stops
receiving version bumps and needs a look at its images before it returns.

## database — CloudNativePG, the Barman Cloud plugin and a shared Postgres

Worked on 2026-09-19: one instance of PostgreSQL 18.6 on the `lvm` class, WAL
archived continuously to Cloudflare R2 and a base backup at 04:00 with 30 day
retention, under `s3://homelab-backups/cnpg`, series `postgres-v2`. It was
built for Paperless and switched off before Paperless existed: the database
held 7.8 MB and no table of its own. See
[`decisions/0019`](../../../docs/decisions/0019-beelink-backups-to-r2.md).

To bring it back:

```sh
git mv core-talos/03-gitops/archive/database/applications core-talos/03-gitops/applications/system/database
git mv core-talos/03-gitops/archive/database/components  core-talos/03-gitops/components/system/database
```

The Cluster carries `bootstrap.recovery` from R2, so a cluster recreated this
way restores itself from the archive rather than starting empty, and then
keeps writing to the same series. That is safe only while the cluster it
recovers from is gone. Its one secret, the R2 key pair, is read from Infisical
at `/backups/R2`; nothing here has to be pasted back by hand.
