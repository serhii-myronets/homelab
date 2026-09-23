---
id: "0017"
title: Split the Beelink NVMe and keep configurations on static volumes
date: 2026-09-19
status: superseded by 0019
tags: [beelink, talos, kubernetes, storage, nvme, openebs]
---

# Split the Beelink NVMe and keep configurations on static volumes

**Superseded by `0019` on 2026-09-19**, once backups to R2 existed: the split
and the static volumes both served to keep data on a disk that was never
copied anywhere.

Application configurations and databases must survive a reinstall of the
cluster, as the media on the HDDs do, and there is no backup yet. OpenEBS
Hostpath names each directory after a generated PVC UID, so a reinstalled
cluster would give every application an empty directory. Configurations
therefore use static `hostPath` PVs with one fixed directory per service,
declared in `03-gitops/apps/system/storage/volumes/app/`.

OpenEBS stays for scratch data such as caches. Both share the 500 GB WD NVMe,
which Talos splits into two XFS volumes: `apps` (100 GB) for the static PVs
and `cache` (399 GB) for OpenEBS. Neither kind of PV enforces a size, so the
split is what stops a growing cache from filling the space the databases
need. It was made while the disk was still empty.

Dynamic PVCs restored by VolSync after a reinstall were the alternative. They
also protect against losing the NVMe itself, but need a backup target that
does not exist yet; they can replace the static PVs when backups arrive. A
spare M.2 slot remains for a backup disk.
