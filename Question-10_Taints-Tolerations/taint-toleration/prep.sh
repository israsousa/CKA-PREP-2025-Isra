#!/usr/bin/env bash
set -euo pipefail

NODE="node01"
POD="taint-test"

kubectl get node "$NODE" >/dev/null

# Reset (idempotent)
kubectl delete pod "$POD" --ignore-not-found >/dev/null 2>&1 || true

# Remove taint if it already exists (ignore if missing)
kubectl taint node "$NODE" IT=codegenitor:NoSchedule- >/dev/null 2>&1 || true

echo "Prep done."
echo "Now solve:"
echo "1) Taint node01 with IT=codegenitor:NoSchedule"
echo "2) Create a pod that tolerates it and lands on node01"
