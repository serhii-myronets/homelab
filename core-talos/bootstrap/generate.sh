#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source ./cluster.env
umask 077
mkdir -p private
chmod 700 private
if [[ ! -s private/secrets.yaml ]]; then
  if [[ -e private/secrets.yaml || -e private/controlplane.yaml || -e private/talosconfig ]]; then
    echo "Secrets missing or empty with existing output; restore the original secrets before generating." >&2
    exit 1
  fi
  talosctl gen secrets --talos-version "$TALOS_VERSION" -o private/secrets.yaml
fi
talosctl gen config "$CLUSTER_NAME" "https://${NODE_IP}:6443" \
  --talos-version "$TALOS_VERSION" \
  --kubernetes-version "$KUBERNETES_VERSION" \
  --install-disk '' \
  --install-image "factory.talos.dev/metal-installer/${SCHEMATIC}:${TALOS_VERSION}" \
  --with-secrets private/secrets.yaml \
  --config-patch-control-plane @controlplane.patch.yaml \
  --output-types controlplane,talosconfig \
  --with-docs=false --with-examples=false \
  --output private --force
talosctl --talosconfig private/talosconfig config endpoint "$NODE_IP"
talosctl --talosconfig private/talosconfig config node "$NODE_IP"
chmod 600 private/*
talosctl validate --config private/controlplane.yaml --mode metal --strict
