---
date: 2026-09-19
title: Copy the scan share to Beelink
tags: [beelink, core, migration, samba, storage]
---

The old Core `scan` share contained 89 document files (about 109 MiB). They
were copied to the empty `scan` share on Beelink without deleting the Core
source. A SHA-256 manifest of all non-AppleDouble files matches at both ends.

The source also held 43 `._*` AppleDouble metadata files. Samba normalizes
those files when writing the new share, so their byte contents differ; they do
not contain the scanned documents. The original source remains available until
the owner chooses to retire Core storage.
