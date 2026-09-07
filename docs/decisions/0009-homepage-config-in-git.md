---
id: 0009
title: Keep the Homepage dashboard configuration in git
status: accepted
date: 2026-09-06
tags: [homepage, gitops, configuration]
hosts: [core]
---

Mount the whole Homepage configuration directory from the Portainer checkout
read-only, with ephemeral logs on tmpfs. The dashboard has no persistent user
data; its configuration can be restored from this repository.

Individual file mounts were rejected because they repeat the stale-inode
failure already recorded in traps. A separate writable configuration copy
would introduce another source of truth. Explicit service links and HTTP
checks cover the initial dashboard without Docker socket access or API keys.
