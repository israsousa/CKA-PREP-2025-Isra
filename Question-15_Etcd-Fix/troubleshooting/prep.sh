#!/usr/bin/env bash
# prep.sh — Control Plane Troubleshooting Lab (BROKEN STATE)
set -euo pipefail

APISERVER_MANIFEST="/etc/kubernetes/manifests/kube-apiserver.yaml"

echo "==> Preparing broken kube-apiserver state..."

if [[ ! -f "$APISERVER_MANIFEST" ]]; then
  echo "ERROR: kube-apiserver manifest not found at $APISERVER_MANIFEST"
  exit 1
fi

# Backup once
if [[ ! -f "${APISERVER_MANIFEST}.bak" ]]; then
  cp "$APISERVER_MANIFEST" "${APISERVER_MANIFEST}.bak"
  echo "==> Backup created at ${APISERVER_MANIFEST}.bak"
fi

# Force wrong etcd peer port (2380)
sed -i 's/:2379/:2380/g' "$APISERVER_MANIFEST"

echo "==> kube-apiserver now incorrectly points to etcd peer port 2380"
echo "==> kubelet will restart the static pod automatically"
echo
echo "🚨 Cluster is now BROKEN on purpose"
echo "Your task: fix kube-apiserver to use etcd client port 2379"
