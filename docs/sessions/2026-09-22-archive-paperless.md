---
title: Archive the empty Paperless trial
date: 2026-09-22
tags: [beelink, paperless, flux, archive, storage]
hosts: [beelink]
---

# Archive the empty Paperless trial

Paperless was running on the Beelink with a fresh, empty database. The owner
chose Google Drive for family documents and explicitly approved deletion of the
empty PV. The service's Flux Kustomization was removed from the root app list,
the manifests were moved to `archive/paperless/`, and `paperless.home` was
removed from the local certificate. Flux removed the Kustomization, namespace,
20 GiB claim and its dynamically provisioned volume; it also removed VolSync's
one GiB cache volume. The reissued local certificate is Ready without
`paperless.home`.
