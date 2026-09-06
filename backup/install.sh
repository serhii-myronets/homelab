#!/usr/bin/env bash
#
# One-time setup for the backup job. Idempotent: safe to re-run.
#
#   sudo ./backup/install.sh
#
set -euo pipefail

REPO_DIR=/var/backups/restic
PASS_FILE=/etc/restic-password
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ok() { printf '  ✓ %s\n' "$*"; }

[[ $EUID -eq 0 ]] || { echo "run as root"; exit 1; }

if command -v restic >/dev/null; then
  ok "restic already installed"
else
  apt-get update -qq && apt-get install -y -qq restic
  ok "restic installed"
fi

if [[ -s "$PASS_FILE" ]]; then
  ok "password file exists"
else
  head -c 32 /dev/urandom | base64 > "$PASS_FILE"
  chmod 600 "$PASS_FILE"
  echo
  echo "  ┌─────────────────────────────────────────────────────────────┐"
  echo "  │ Generated a repository password. Without it the backups are │"
  echo "  │ unreadable. Save it somewhere off this machine, now:        │"
  echo "  └─────────────────────────────────────────────────────────────┘"
  echo
  echo "      $(cat "$PASS_FILE")"
  echo
fi

export RESTIC_REPOSITORY="$REPO_DIR"
export RESTIC_PASSWORD_FILE="$PASS_FILE"

if restic cat config >/dev/null 2>&1; then
  ok "repository exists at $REPO_DIR"
else
  restic init >/dev/null
  ok "repository initialised at $REPO_DIR"
fi

# Point the unit at wherever this checkout happens to live.
sed "s|__BACKUP_SH__|$HERE/backup.sh|" "$HERE/restic-backup.service" \
  > /etc/systemd/system/restic-backup.service
cp "$HERE/restic-backup.timer" /etc/systemd/system/restic-backup.timer
systemctl daemon-reload
systemctl enable --now restic-backup.timer >/dev/null
ok "daily timer enabled"

echo
echo "  Run it now:      systemctl start restic-backup.service"
echo "  Watch it:        journalctl -u restic-backup -f"
echo "  List snapshots:  RESTIC_REPOSITORY=$REPO_DIR RESTIC_PASSWORD_FILE=$PASS_FILE restic snapshots"
