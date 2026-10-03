#!/bin/sh
# Installs the router's metrics exporter - OpenWrt's own Lua rewrite of
# node_exporter - and points it at the LAN, from the Mac. The second thing
# this repository installs on the router over ssh, under the same narrow
# exception as Gatus: a package from the router's own feed and that package's
# own configuration, nothing GL.iNet manages. See docs/decisions/0036.
#
# Safe to run again. A firmware upgrade keeps the configuration but not the
# packages, and a reflash loses both: run it again after either.
set -eu

ROUTER=root@192.168.8.1

ssh -o BatchMode=yes "$ROUTER" '
	set -e
	opkg update >/dev/null
	# The base collectors - CPU, memory, interfaces, conntrack - plus the
	# board and firmware, and how many clients each Wi-Fi radio has.
	opkg install prometheus-node-exporter-lua \
		prometheus-node-exporter-lua-openwrt \
		prometheus-node-exporter-lua-wifi_stations >/dev/null
	# The package listens on loopback; the LAN is where vmagent scrapes from.
	uci set prometheus-node-exporter-lua.main.listen_interface=lan
	uci set prometheus-node-exporter-lua.main.listen_port=9100
	uci commit prometheus-node-exporter-lua
	/etc/init.d/prometheus-node-exporter-lua enable
	# Stop, then start: the package starts itself on install, bound to
	# loopback, and a restart left that instance running.
	/etc/init.d/prometheus-node-exporter-lua stop
	sleep 1
	/etc/init.d/prometheus-node-exporter-lua start
'
echo "node exporter on the router: http://192.168.8.1:9100/metrics"
