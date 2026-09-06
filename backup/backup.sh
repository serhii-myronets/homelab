#!/usr/bin/env bash
#
# Each disk holds the backup of what lives on the other one, so losing either
# leaves a copy on the survivor. Losing the machine loses both.
#
#   sda (ORICO, 1.9T)  data, secrets, shares  ->  repository on sdb
#   sdb (system SSD)   OMV's configuration    ->  repository on sda
#
set -euo pipefail

export RESTIC_PASSWORD_FILE=${RESTIC_PASSWORD_FILE:-/etc/restic-password}

run() {
  local repo=$1; shift
  printf '\n\033[1m→ %s\033[0m\n' "$repo"
  RESTIC_REPOSITORY="$repo" restic backup --exclude-caches "$@"
  RESTIC_REPOSITORY="$repo" restic forget \
    --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune
}

# Everything on sda worth keeping. The Jellyfin excludes are what keeps this
# at ~220 MB instead of 13 GB: cache and metadata are artwork and transcodes
# that a library scan downloads again. Its data/ holds library.db — watch
# history, users, playlists — and that is the part that cannot come back.
run /var/backups/restic \
  --exclude /srv/ssd/docker/data/jellyfin/cache \
  --exclude /srv/ssd/docker/data/jellyfin/config/metadata \
  --exclude /srv/ssd/docker/data/jellyfin/config/log \
  /srv/ssd/docker/data \
  /srv/ssd/docker/secrets \
  /srv/ssd/samba/scan \
  /srv/ssd/samba/doc

# OpenMediaVault keeps its entire configuration in this one file — shares,
# disk mounts, SMART, users, network — and offers no way to version it.
run /srv/ssd/backups/restic \
  /etc/openmediavault/config.xml
