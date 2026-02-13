#!/usr/bin/env bash
set -euo pipefail

NODE="node01"
POD="taint-test"

green() { printf "\e[32m%s\e[0m\n" "$1"; }
red()   { printf "\e[31m%s\e[0m\n" "$1"; }

fail() { red "FAIL: $*"; exit 1; }
pass() { green "PASS: $*"; }

echo "=== CHECK: Taints & Tolerations ==="

kubectl get node "$NODE" >/dev/null 2>&1 || fail "node $NODE not found"

TAINTS="$(kubectl get node "$NODE" -o jsonpath='{range .spec.taints[*]}{.key}{"="}{.value}{":"}{.effect}{"\n"}{end}' 2>/dev/null || true)"
echo "$TAINTS" | grep -qx "IT=codegenitor:NoSchedule" || fail "Expected taint IT=codegenitor:NoSchedule not found on $NODE"

kubectl get pod "$POD" >/dev/null 2>&1 || fail "Pod $POD not found in default namespace"

NODE_NAME="$(kubectl get pod "$POD" -o jsonpath='{.spec.nodeName}' 2>/dev/null || true)"
[[ "$NODE_NAME" == "$NODE" ]] || fail "Pod $POD is not scheduled on $NODE (found: ${NODE_NAME:-<none>})"

PHASE="$(kubectl get pod "$POD" -o jsonpath='{.status.phase}' 2>/dev/null || true)"
[[ "$PHASE" == "Running" ]] || fail "Pod $POD is not Running (phase: ${PHASE:-<unknown>})"

TOLS="$(kubectl get pod "$POD" -o jsonpath='{range .spec.tolerations[*]}{.key}{"="}{.value}{":"}{.effect}{"\n"}{end}' 2>/dev/null || true)"
echo "$TOLS" | grep -qx "IT=codegenitor:NoSchedule" || fail "Pod $POD does not have toleration IT=codegenitor:NoSchedule"

pass "node01 tainted correctly; Pod ${POD} tolerates and runs on node01."
