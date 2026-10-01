#!/bin/sh
# Installs Gatus on the router, or updates it - its version, its checks, its
# start script - run from the Mac, from anywhere. The only thing in this
# repository that writes to the router over ssh, and only Gatus's own files:
# /opt/gatus, /etc/gatus, /etc/init.d/gatus and three lines of
# /etc/sysupgrade.conf, nothing the GL.iNet firmware manages. See
# docs/decisions/0036.
#
# Safe to run again, and the way every change reaches the router: edit
# config.yaml, run this. After a reflash it is the whole recovery.
set -eu

VERSION=v5.37.0
ROUTER=root@192.168.8.1
HERE=$(cd "$(dirname "$0")" && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

on_router() { ssh -o BatchMode=yes "$ROUTER" "$@"; }
put() { on_router "cat > '$2'" < "$1"; }
same() { [ "$(md5 -q "$1")" = "$(on_router "md5sum < '$2' 2>/dev/null" | cut -d' ' -f1)" ]; }

on_router 'mkdir -p /opt/gatus /etc/gatus/certs'
# `install.sh restart` also restarts Gatus - the way to pick up a changed
# /etc/gatus/env, which this script never reads or writes.
restart=no
[ "${1:-}" = restart ] && restart=yes

# The binary, only when the version moves: from the official image's
# linux/arm64 layers - the build the cluster ran - read straight from the
# registry, so no Docker is needed.
if [ "$(on_router 'cat /opt/gatus/VERSION 2>/dev/null' || true)" != "$VERSION" ]; then
	python3 - "$VERSION" "$TMP/gatus" <<'PY'
import io, json, sys, tarfile, urllib.request
tag, out = sys.argv[1], sys.argv[2]
repo = "twin/gatus"
def get(url, token=None, accept=None):
    req = urllib.request.Request(url)
    if token: req.add_header("Authorization", "Bearer " + token)
    if accept: req.add_header("Accept", accept)
    return urllib.request.urlopen(req).read()
token = json.loads(get(f"https://ghcr.io/token?scope=repository:{repo}:pull"))["token"]
index = json.loads(get(f"https://ghcr.io/v2/{repo}/manifests/{tag}", token,
    "application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.list.v2+json"))
digest = next(m["digest"] for m in index["manifests"]
              if m["platform"]["os"] == "linux" and m["platform"]["architecture"] == "arm64")
manifest = json.loads(get(f"https://ghcr.io/v2/{repo}/manifests/{digest}", token,
    "application/vnd.oci.image.manifest.v1+json, application/vnd.docker.distribution.manifest.v2+json"))
for layer in manifest["layers"]:
    with tarfile.open(fileobj=io.BytesIO(get(f"https://ghcr.io/v2/{repo}/blobs/{layer['digest']}", token))) as t:
        for m in t.getmembers():
            if m.name.lstrip("./") == "gatus" and m.isfile():
                open(out, "wb").write(t.extractfile(m).read())
                sys.exit(0)
sys.exit("no /gatus in the linux/arm64 image")
PY
	put "$TMP/gatus" /opt/gatus/gatus.new
	on_router "mv /opt/gatus/gatus.new /opt/gatus/gatus && chmod 755 /opt/gatus/gatus && echo $VERSION > /opt/gatus/VERSION"
	restart=yes
fi

if ! same "$HERE/gatus.init" /etc/init.d/gatus; then
	put "$HERE/gatus.init" /etc/init.d/gatus
	restart=yes
fi

# The checks. Gatus rereads the file when it changes, so this alone needs no
# restart.
same "$HERE/config.yaml" /etc/gatus/config.yaml || put "$HERE/config.yaml" /etc/gatus/config.yaml

# home-ca's certificate, as any device fetches it, so *.home verifies.
curl -fsS http://ca.home/root.crt -o "$TMP/home-ca.crt"
same "$TMP/home-ca.crt" /etc/gatus/certs/home-ca.crt || { put "$TMP/home-ca.crt" /etc/gatus/certs/home-ca.crt; restart=yes; }

on_router "
	set -e
	chmod 755 /etc/init.d/gatus
	chmod 644 /etc/gatus/config.yaml /etc/gatus/certs/home-ca.crt
	[ -f /etc/gatus/env ] || { touch /etc/gatus/env; chmod 600 /etc/gatus/env; }
	# Kept through a firmware upgrade; a reflash loses them, and this script
	# puts them back.
	for p in /opt/gatus/ /etc/gatus/ /etc/init.d/gatus; do
		grep -qxF \"\$p\" /etc/sysupgrade.conf || echo \"\$p\" >> /etc/sysupgrade.conf
	done
	/etc/init.d/gatus enable
	if [ $restart = yes ] || ! pgrep -f /opt/gatus/gatus >/dev/null; then /etc/init.d/gatus restart; fi
"
echo "Gatus $VERSION on the router: http://192.168.8.1:8090"
