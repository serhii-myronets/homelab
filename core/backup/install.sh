#!/usr/bin/env bash
#
# One-time setup for the backup job. Idempotent: safe to re-run.
#
#   sudo ./core/backup/install.sh
#
set -euo pipefail

LOCAL_REPOS=(/var/backups/restic /srv/ssd/backups/restic)
REMOTE_REPO=sftp:proxmox-backup:/var/lib/vz/backups/restic
REMOTE_HOST=10.1.1.100
KEY=/root/.ssh/id_ed25519_backup
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

export RESTIC_PASSWORD_FILE="$PASS_FILE"

for repo in "${LOCAL_REPOS[@]}"; do
  export RESTIC_REPOSITORY="$repo"
  if restic cat config >/dev/null 2>&1; then
    ok "repository exists at $repo"
  else
    mkdir -p "$(dirname "$repo")"
    restic init >/dev/null
    ok "repository initialised at $repo"
  fi
done

# The third repository lives on the Proxmox box, so losing this machine does
# not lose every copy. Its own key, restricted to sftp on the far side.
if [[ -f "$KEY" ]]; then
  ok "backup key exists"
else
  ssh-keygen -t ed25519 -N '' -C "restic-backup@$(hostname)" -f "$KEY" -q
  ok "backup key generated"
fi

# A host alias rather than a global entry, so this key is used for the backup
# and nothing else.
if grep -q '^Host proxmox-backup$' /root/.ssh/config 2>/dev/null; then
  ok "ssh alias configured"
else
  cat >> /root/.ssh/config <<CFG

Host proxmox-backup
    HostName $REMOTE_HOST
    User root
    IdentityFile $KEY
    IdentitiesOnly yes
    BatchMode yes
    StrictHostKeyChecking accept-new
CFG
  chmod 600 /root/.ssh/config
  ok "ssh alias configured"
fi

if printf 'quit\n' | sftp -q -b - proxmox-backup >/dev/null 2>&1; then
  export RESTIC_REPOSITORY="$REMOTE_REPO"
  if restic cat config >/dev/null 2>&1; then
    ok "repository exists at $REMOTE_REPO"
  else
    restic init >/dev/null
    ok "repository initialised at $REMOTE_REPO"
  fi
else
  echo
  echo "  ! $REMOTE_HOST is not reachable over sftp yet. Authorise this key"
  echo "    there — it is restricted to file transfer, no shell:"
  echo
  echo "      echo 'restrict,command=\"internal-sftp\" $(cat "$KEY.pub")' \\"
  echo "        | ssh root@$REMOTE_HOST 'cat >> /root/.ssh/authorized_keys'"
  echo
  echo "    Then re-run this script. Local backups work without it."
  echo
fi

# Without this copy, losing the system SSD would leave the surviving
# repository unreadable.
install -m 600 "$PASS_FILE" /srv/ssd/backups/password
ok "password copied next to the data-disk repository"

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
echo "  List snapshots:  RESTIC_REPOSITORY=${LOCAL_REPOS[0]} RESTIC_PASSWORD_FILE=$PASS_FILE restic snapshots"
