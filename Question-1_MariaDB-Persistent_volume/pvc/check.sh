#!/usr/bin/env bash
# check.sh — PVC Question Validator
set -euo pipefail

NS="mariadb"
PVC="mariadb"
DEPLOY="mariadb"

green() { printf "\e[32m%s\e[0m\n" "$1"; }
red() { printf "\e[31m%s\e[0m\n" "$1"; }
fail() { red "FAIL: $*"; exit 1; }
pass() { green "PASS: $*"; }

echo "=== CHECK: PVC + Deployment ==="

kubectl get ns "$NS" >/dev/null 2>&1 || fail "Namespace $NS missing"

kubectl -n "$NS" get pvc "$PVC" >/dev/null 2>&1 || fail "PVC '$PVC' not found"

AM="$(kubectl -n "$NS" get pvc "$PVC" -o jsonpath='{.spec.accessModes[0]}')"
REQ="$(kubectl -n "$NS" get pvc "$PVC" -o jsonpath='{.spec.resources.requests.storage}')"

[[ "$AM" == "ReadWriteOnce" ]] || fail "PVC accessMode is not ReadWriteOnce"
[[ "$REQ" == "250Mi" ]] || fail "PVC size is not 250Mi"

PHASE="$(kubectl -n "$NS" get pvc "$PVC" -o jsonpath='{.status.phase}')"
[[ "$PHASE" == "Bound" ]] || fail "PVC is not Bound"

kubectl -n "$NS" get deploy "$DEPLOY" >/dev/null 2>&1 || fail "Deployment not found"

CLAIM="$(kubectl -n "$NS" get deploy "$DEPLOY" -o jsonpath='{.spec.template.spec.volumes[*].persistentVolumeClaim.claimName}')"
[[ "$CLAIM" == *"$PVC"* ]] || fail "Deployment does not reference PVC '$PVC'"

READY="$(kubectl -n "$NS" get deploy "$DEPLOY" -o jsonpath='{.status.readyReplicas}')"
[[ -n "$READY" && "$READY" -ge 1 ]] || fail "Deployment is not ready"

pass "PVC exists, is Bound, Deployment uses it, and Pods are running"
