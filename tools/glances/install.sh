#!/usr/bin/env bash
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo 'Run as root'; exit 1; }
bind_address=${1:?Usage: install.sh HOST_LAN_IP}
[[ $bind_address =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || exit 1
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y python3-venv
python3 -m venv /opt/glances-homepage
/opt/glances-homepage/bin/pip install 'glances[web]==4.5.6'
cat > /etc/systemd/system/glances-homepage.service <<UNIT
[Unit]
Description=Host metrics for Homepage
After=network-online.target
Wants=network-online.target

[Service]
User=nobody
Group=nogroup
Environment=HOME=/var/lib/glances-homepage
StateDirectory=glances-homepage
ExecStart=/opt/glances-homepage/bin/glances -w -B ${bind_address} --disable-process
Restart=on-failure
RestartSec=5
NoNewPrivileges=true
ProtectSystem=full

[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable glances-homepage
systemctl restart glances-homepage
