#!/bin/sh
# Opens the API of the router's AdGuard Home to the clusters' external-dns,
# run from the Mac, from anywhere: each cluster gets an AdGuard user, and
# AdGuard runs without --glinet, which otherwise admits only GL.iNet's own
# admin session. Unlike Gatus and the exporter, this edits two files the
# firmware owns - /etc/AdGuardHome/config.yaml and /etc/init.d/adguardhome -
# see docs/decisions/0038.
#
# Safe to run again, and the way back after a firmware upgrade, which puts
# --glinet back. A user's password lives in its cluster's Infisical project,
# /system/adguard/USERNAME and PASSWORD; a cluster without them is left out.
# Each file is copied to /root/agh-backup-<time> before it is changed.
set -eu

ROUTER=root@192.168.8.1
API=http://192.168.8.1:3000
# Infisical project IDs: core's homelab, then the lab's proxmox-lab.
PROJECTS="0f683ac6-7321-435c-935e-3e68f72f2d60 31407031-ddd9-4d01-aaa4-b9a791c73504"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

on_router() { ssh -o BatchMode=yes "$ROUTER" "$@"; }
secret() {
	infisical secrets get "$2" --projectId "$1" --env prod --path /system/adguard \
		--plain --silent 2>/dev/null || true
}
# HTTP status of the API for one user; the password goes through curl's
# config on stdin, never on a command line.
status() {
	printf 'user = "%s:%s"\n' "$1" "$2" |
		curl -s -o /dev/null -w '%{http_code}' -K - "$API/control/status" || true
}

# The users block, and whether every user already gets in.
printf 'users:\n' > "$TMP/users"
current=yes
for project in $PROJECTS; do
	name=$(secret "$project" USERNAME)
	password=$(secret "$project" PASSWORD)
	[ -n "$name" ] && [ -n "$password" ] || continue
	hash=$(printf '%s' "$password" | htpasswd -niBC 10 "$name" | cut -d: -f2- | sed 's/^\$2y\$/$2a$/')
	printf '  - name: %s\n    password: %s\n' "$name" "$hash" >> "$TMP/users"
	[ "$(status "$name" "$password")" = 200 ] || current=no
	echo "user $name"
done
[ "$(wc -l < "$TMP/users")" -gt 1 ] || { echo "no user in Infisical" >&2; exit 1; }

glinet=$(on_router 'grep -c -- " --glinet " /etc/init.d/adguardhome || true')
if [ "$current" = yes ] && [ "$glinet" = 0 ]; then
	echo "AdGuard API already open to every user; nothing to do"
	exit 0
fi

# Back up, then replace the whole users block and drop --glinet. The block
# runs from "users:" to the next top-level key.
on_router 'cat > /tmp/agh-users.yaml' < "$TMP/users"
on_router '
	set -e
	d=/root/agh-backup-$(date +%Y%m%d-%H%M%S); mkdir -p "$d"
	cp -p /etc/AdGuardHome/config.yaml /etc/init.d/adguardhome "$d"/
	awk "FNR==NR {u = u \$0 \"\n\"; next}
	     /^users:/ {printf \"%s\", u; skip = 1; next}
	     skip && /^[^ -]/ {skip = 0}
	     !skip {print}" /tmp/agh-users.yaml /etc/AdGuardHome/config.yaml > /tmp/agh-config.yaml
	grep -q "^users:" /tmp/agh-config.yaml
	cat /tmp/agh-config.yaml > /etc/AdGuardHome/config.yaml
	rm /tmp/agh-users.yaml /tmp/agh-config.yaml
	sed -i "s/ --glinet / /" /etc/init.d/adguardhome
	/etc/init.d/adguardhome restart >/dev/null 2>&1
	echo "backup in $d"
'

# The house's DNS first, then the API for each user.
sleep 5
dig +short +time=2 @192.168.8.1 example.com | grep -q . || {
	echo "DNS does not answer - restore the backup above" >&2
	exit 1
}
for project in $PROJECTS; do
	name=$(secret "$project" USERNAME)
	password=$(secret "$project" PASSWORD)
	[ -n "$name" ] && [ -n "$password" ] || continue
	echo "API for $name: $(status "$name" "$password")"
done
