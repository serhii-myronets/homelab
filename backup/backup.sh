#!/usr/bin/env bash
#
# Backs up everything that cannot be re-downloaded to a restic repository on
# the system SSD. That protects against the data disk dying, which is the
# likelier failure — sda runs torrents around the clock while sdb barely moves.
# It does NOT protect against losing the machine; add an off-box target for
# that.
#
# Roughly 2 GB on the first run, a few MB per day afterwards.
#
set -euo pipefail

export RESTIC_REPOSITORY=${RESTIC_REPOSITORY:-/var/backups/restic}
export RESTIC_PASSWORD_FILE=${RESTIC_PASSWORD_FILE:-/etc/restic-password}

# Both the repository and the password live on the system SSD on purpose: if
# the data disk dies, they have to still be readable.
restic backup \
  --verbose \
  --exclude /srv/ssd/docker/data/jellyfin/cache \
  --exclude-caches \
  /srv/ssd/docker/data \
  /srv/ssd/docker/secrets \
  /srv/ssd/samba/scan \
  /srv/ssd/samba/doc \
  /etc/openmediavault/config.xml

# OpenMediaVault keeps its entire configuration in that one XML file and offers
# no way to version it, so it rides along here.

restic forget \
  --keep-daily 7 \
  --keep-weekly 4 \
  --keep-monthly 6 \
  --prune
