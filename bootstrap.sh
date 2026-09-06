#!/usr/bin/env bash
#
# Brings a bare host to the point where Portainer is running and can take over
# the remaining stacks. Idempotent: safe to re-run.
#
#   ./bootstrap.sh
#
set -euo pipefail

DATA=/srv/ssd/docker/data
SECRETS=/srv/ssd/docker/secrets
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

say() { printf '\n\033[1m%s\033[0m\n' "$*"; }
ok()  { printf '  ✓ %s\n' "$*"; }
bad() { printf '  ✗ %s\n' "$*"; }

[[ $EUID -eq 0 ]] || { echo "run as root"; exit 1; }

say "Docker"
if command -v docker >/dev/null; then
  ok "already installed"
else
  curl -fsSL https://get.docker.com | sh
  ok "installed"
fi

say "Shared network"
# Every stack joins this as an external network, so nothing else creates it.
if docker network inspect backend >/dev/null 2>&1; then
  ok "backend exists"
else
  docker network create backend >/dev/null
  ok "backend created"
fi

say "Data directories"
# One directory per stack, mirroring the stack directories in this repo.
for d in caddy/data caddy/config jellyfin/config jellyfin/cache \
         torrent/gluetun torrent/qbittorrent torrent/flood portainer/data; do
  if [[ -d "$DATA/$d" ]]; then
    ok "$d (exists)"
  else
    mkdir -p "$DATA/$d"
    ok "$d (created)"
  fi
done

# Flood runs as uid/gid 1001 ("download") and honours neither PUID nor PGID,
# so its rundir has to be owned by 1001 or it cannot write its database.
if [[ "$(stat -c '%u:%g' "$DATA/torrent/flood")" == "1001:1001" ]]; then
  ok "torrent/flood already owned by 1001:1001"
else
  chown -R 1001:1001 "$DATA/torrent/flood"
  ok "torrent/flood chowned to 1001:1001"
fi

say "Secrets"
# Never in git; this only checks they are there.
missing=0
while read -r path desc; do
  if [[ -s "$SECRETS/$path" ]]; then
    ok "$path"
  else
    bad "$path — $desc"
    missing=1
  fi
done <<'EOF'
portainer/license.env PORTAINER_LICENSE_KEY=... (Portainer EE licence)
cloudflared/auth.env Cloudflare tunnel token
nordvpn/user NordVPN OpenVPN username
nordvpn/pass NordVPN OpenVPN password
EOF

if [[ $missing -eq 1 ]]; then
  echo
  echo "Create the missing files under $SECRETS (mode 600), then re-run."
  exit 1
fi

say "Portainer"
docker compose -f "$REPO/portainer/docker-compose.yaml" up -d
ok "up — https://portainer.home (or http://$(hostname -I | awk '{print $1}'):9000)"

say "Next"
cat <<'EOF'
  Add the remaining stacks in Portainer (Stacks -> Add stack -> Repository),
  reference refs/heads/main. See the table in README.md for each stack's
  compose path and relative-path-volume settings.
EOF
