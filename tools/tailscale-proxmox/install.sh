#!/usr/bin/env bash
set -euo pipefail

route_cidr="10.1.1.0/24"
sysctl_file="/etc/sysctl.d/99-tailscale-subnet-router.conf"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run this installer as root." >&2
  exit 1
fi

if [[ ! -f /etc/debian_version ]]; then
  echo "This installer expects a Debian-based Proxmox host." >&2
  exit 1
fi

if ! command -v tailscale >/dev/null 2>&1; then
  apt-get update
  apt-get install -y curl
  curl -fsSL https://tailscale.com/install.sh | sh
fi

install -d -m 0755 /etc/sysctl.d
cat > "${sysctl_file}" <<'EOF'
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
EOF
sysctl --system >/dev/null

if [[ -n "${TAILSCALE_AUTH_KEY:-}" ]]; then
  tailscale up \
    --auth-key="${TAILSCALE_AUTH_KEY}" \
    --advertise-routes="${route_cidr}" \
    --accept-dns=false
elif tailscale status >/dev/null 2>&1; then
  tailscale set \
    --advertise-routes="${route_cidr}" \
    --accept-dns=false
else
  tailscale up \
    --advertise-routes="${route_cidr}" \
    --accept-dns=false
fi

unset TAILSCALE_AUTH_KEY
echo "Tailscale is configured to advertise ${route_cidr}. Approve the route in the Tailscale admin console."
