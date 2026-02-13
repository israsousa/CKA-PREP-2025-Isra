#!/usr/bin/env bash
# check.sh — Control Plane Troubleshooting Validator
set -euo pipefail

APISERVER_MANIFEST="/etc/kubernetes/manifests/kube-apiserver.yaml"

green() { printf "\e[32m%s\e[0m\n" "$1"; }
red()   { printf "\e[31m%s\e[0m\n" "$1"; }

fail() { red "FAIL: $*"; exit 1; }
pass() { green "PASS: $*"; }

echo "=== CHECK: kube-apiserver / etcd configuration ==="

[[ -f "$APISERVER_MANIFEST" ]] || fail "kube-apiserver manifest not found"

# Validate etcd client port
grep -q -- "--etcd-servers=.*:2379" "$APISERVER_MANIFEST" \
  || fail "kube-apiserver is NOT using etcd client port 2379"

# Ensure peer port is NOT used
grep -q -- ":2380" "$APISERVER_MANIFEST" \
  && fail "kube-apiserver still references etcd peer port 2380"

echo "==> etcd endpoint configuration looks correct"

# Check kube-apiserver container is running
if crictl ps | grep -q kube-apiserver; then
  echo "==> kube-apiserver container is running"
else
  fail "kube-apiserver container is not running"
fi

# Verify API server responsiveness
if kubectl get nodes >/dev/null 2>&1; then
  pass "kube-apiserver is healthy and kubectl works"
else
  fail "kubectl cannot communicate with the API server"
fi
