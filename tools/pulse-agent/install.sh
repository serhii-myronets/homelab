#!/usr/bin/env bash
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo 'Run as root'; exit 1; }
pulse_url=${1:?Usage: install.sh PULSE_URL AGENT_TOKEN [--enable-proxmox]}
agent_token=${2:?Usage: install.sh PULSE_URL AGENT_TOKEN [--enable-proxmox]}
shift 2

curl -fsSL "${pulse_url%/}/install.sh" | \
  bash -s -- --url "${pulse_url%/}" --token "$agent_token" "$@"
