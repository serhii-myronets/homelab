#!/usr/bin/env bash
#
# Backs up everything that cannot be re-downloaded, to one repository on each
# disk. Neither disk is redundant, so each repository covers the other's
# failure: lose sda and the copy on sdb restores it, lose sdb and the copy on
# sda does. Losing the machine loses both — that needs an off-box target.
#
# Roughly 2 GB per repository on the first run, a few MB per day afterwards.
#
set -euo pipefail

PASS_FILE=${RESTIC_PASSWORD_FILE:-/etc/restic-password}

# sdb (system SSD) first, sda (ORICO) second.
REPOS=(
  /var/backups/restic
  /srv/ssd/backups/restic
)

PATHS=(
  /srv/ssd/docker/data
  /srv/ssd/docker/secrets
  /srv/ssd/samba/scan
  /srv/ssd/samba/doc
  # OpenMediaVault keeps its whole configuration in this one file — samba
  # shares, disk mounts, SMART, users, network — and offers no way to version
  # it, so it rides along here.
  /etc/openmediavault/config.xml
  # Not covered by the git repo either: host keys, so clients do not trip over
  # a changed fingerprint after a rebuild.
  /etc/ssh
)

export RESTIC_PASSWORD_FILE="$PASS_FILE"

for repo in "${REPOS[@]}"; do
  printf '\n\033[1m%s\033[0m\n' "→ $repo"
  export RESTIC_REPOSITORY="$repo"

  restic backup \
    --exclude /srv/ssd/docker/data/jellyfin/cache \
    --exclude-caches \
    "${PATHS[@]}"

  restic forget \
    --keep-daily 7 \
    --keep-weekly 4 \
    --keep-monthly 6 \
    --prune
done
