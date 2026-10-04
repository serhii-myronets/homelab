#!/bin/sh
# Installs BIND on the router as the authoritative server for .home, run from
# the Mac, from anywhere - see docs/decisions/0039. Under the same exception
# as Gatus and the exporter (0036): a package from the router's own feed and
# that package's own configuration, nothing GL.iNet manages.
#
# Safe to run again. A firmware upgrade keeps /etc/bind (sysupgrade.conf
# below) but not the package: run it again after an upgrade, and after a
# reflash. What it does not do is the one setting in AdGuard Home - the
# upstream [/home/]127.0.0.1:5300, set in AdGuard's own UI.
set -eu

ROUTER=root@192.168.8.1
HERE=$(cd "$(dirname "$0")" && pwd)
# Infisical project IDs: core's homelab, then the lab's proxmox-lab.
PROJECTS="0f683ac6-7321-435c-935e-3e68f72f2d60 31407031-ddd9-4d01-aaa4-b9a791c73504"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

on_router() { ssh -o BatchMode=yes "$ROUTER" "$@"; }
put() { on_router "cat > '$2'" < "$1"; }
same() { [ "$(md5 -q "$1")" = "$(on_router "[ -f '$2' ] && md5sum < '$2'" | cut -d' ' -f1)" ]; }
secret() {
	infisical secrets get "$2" --projectId "$1" --env prod --path /system/bind \
		--plain --silent 2>/dev/null || true
}

# The clusters' keys, from their Infisical projects.
: > "$TMP/keys.conf"
for project in $PROJECTS; do
	name=$(secret "$project" TSIG_KEY)
	value=$(secret "$project" TSIG_SECRET)
	[ -n "$name" ] && [ -n "$value" ] || continue
	printf 'key "%s" {\n\talgorithm hmac-sha256;\n\tsecret "%s";\n};\n' "$name" "$value" >> "$TMP/keys.conf"
	echo "key $name"
done
[ -s "$TMP/keys.conf" ] || { echo "no TSIG key in Infisical" >&2; exit 1; }

# The packages, once: the server, named-checkconf and named-checkzone, and
# rndc-confgen, which the package's init script runs on every start. The
# server's postinst starts named with the default configuration, which would
# reach for port 53; it is stopped at once.
PACKAGES="bind-server bind-check bind-rndc"
if [ "$(on_router 'opkg list-installed' | grep -c -E "^($(echo $PACKAGES | tr ' ' '|')) ")" != 3 ]; then
	on_router "opkg update >/dev/null && opkg install $PACKAGES >/dev/null; /etc/init.d/named stop >/dev/null 2>&1 || true"
	echo "installed $PACKAGES"
fi

restart=no
same "$HERE/named.conf" /etc/bind/named.conf || { put "$HERE/named.conf" /etc/bind/named.conf; restart=yes; }
same "$TMP/keys.conf" /etc/bind/keys.conf || { put "$TMP/keys.conf" /etc/bind/keys.conf; restart=yes; }
# The zone only when there is none: named owns it once it runs.
if ! on_router '[ -f /etc/bind/dynamic/db.home ]'; then
	on_router 'mkdir -p /etc/bind/dynamic'
	put "$HERE/db.home" /etc/bind/dynamic/db.home
	restart=yes
fi

on_router "
	set -e
	# The bind user exists once the init script has run.
	grep -q '^bind:' /etc/passwd || { /etc/init.d/named start; /etc/init.d/named stop; }
	chown root:bind /etc/bind/keys.conf; chmod 640 /etc/bind/keys.conf
	chown -R bind:bind /etc/bind/dynamic; chmod 750 /etc/bind/dynamic
	named-checkconf /etc/bind/named.conf
	named-checkzone -q home /etc/bind/dynamic/db.home
	# Kept through a firmware upgrade; a reflash loses them, and this script
	# puts them back.
	grep -qx '/etc/bind/' /etc/sysupgrade.conf || echo '/etc/bind/' >> /etc/sysupgrade.conf
	/etc/init.d/named enable
"
if [ "$restart" = yes ] || ! on_router 'pidof named >/dev/null'; then
	on_router '/etc/init.d/named restart'
fi

# Answers .home on 5300, and has left 53 to dnsmasq.
sleep 2
dig +short +time=2 -p 5300 @192.168.8.1 SOA home | grep -q 'ns.home' || {
	echo "named does not answer for .home on 5300" >&2
	exit 1
}
dig +short +time=2 @192.168.8.1 example.com | grep -q . || {
	echo "the house's DNS does not answer - check port 53" >&2
	exit 1
}
echo "BIND answers .home on 192.168.8.1:5300"
