---
id: "0023"
title: Archive the empty Paperless trial
date: 2026-09-22
status: accepted
tags: [beelink, paperless, documents, storage, archive]
---

# Archive the empty Paperless trial

Paperless-ngx was installed for household documents, but no documents were
added. Google Drive already provides the required shared storage and folder
organisation, while Paperless would add OCR workflows and another application
to operate for little present benefit.

The application is removed from Flux and its 20 GiB dynamically provisioned
volume is deliberately deleted. Its manifests remain whole under
`archive/paperless/`, so a future need for scanned-paper OCR can restore the
same design. `paperless.home` is removed from the local certificate at the
same time.

Keeping it running was rejected because its idle use was about 700 MiB of RAM.
Replacing Google Drive with a self-hosted file cloud is deferred until there is
a requirement that Google Drive cannot meet.
