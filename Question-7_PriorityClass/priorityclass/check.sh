#!/usr/bin/env bash
# check.sh — PriorityClass Lab Validator (PASS/FAIL)
set -euo pipefail

NS="priority"
DEPLOY="busybox-logger"
PC="high-priority"

green() { printf "\e[32m%s\e[0m\n" "$1"; }
red()   { printf "\e[31m%s\e[0m\n" "$1"; }

fail() { red "FAIL: $*"; exit 1; }
pass() { green "PASS: $*"; }

echo "=== CHECK: PriorityClass ==="

kubectl get ns "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found"
kubectl -n "$NS" get deploy "$DEPLOY" >/dev/null 2>&1 || fail "Deployment '$DEPLOY' not found in namespace '$NS'"

# PriorityClass is CLUSTER-SCOPED (no namespace)
kubectl get priorityclass "$PC" >/dev/null 2>&1 || fail "PriorityClass '$PC' not found"

HP_VALUE="$(kubectl get priorityclass "$PC" -o jsonpath='{.value}')"
[[ -n "$HP_VALUE" ]] || fail "Could not read value for PriorityClass '$PC'"

# Compute "highest existing user-defined PriorityClass" value:
# - ignore system-* (system-node-critical/system-cluster-critical)
# - ignore the target 'high-priority' itself (so we compare against what existed before)
HIGHEST_USER_DEFINED="$(
  kubectl get priorityclass -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.value}{"\n"}{end}' \
  | awk -F'\t' '
      $1 ~ /^system-/ { next }
      $1 == "high-priority" { next }
      { print $2 }
    ' \
  | sort -n \
  | tail -n 1
)"

[[ -n "$HIGHEST_USER_DEFINED" ]] || fail "Could not determine highest user-defined PriorityClass (excluding system-*)."

EXPECTED=$((HIGHEST_USER_DEFINED - 1))

[[ "$HP_VALUE" -eq "$EXPECTED" ]] || fail "PriorityClass '$PC' has value '$HP_VALUE' but expected '$EXPECTED' (highest user-defined '$HIGHEST_USER_DEFINED' minus 1)"

# Validate the DEPLOYMENT TEMPLATE is patched (pods will follow on rollout)
DEPLOY_PC="$(kubectl -n "$NS" get deploy "$DEPLOY" -o jsonpath='{.spec.template.spec.priorityClassName}' 2>/dev/null || true)"
[[ "$DEPLOY_PC" == "$PC" ]] || fail "Deployment '$DEPLOY' does not set spec.template.spec.priorityClassName to '$PC' (found: '${DEPLOY_PC:-<empty>}')"

# Optional: ensure running pods actually carry it (after rollout)
POD_COUNT="$(kubectl -n "$NS" get pods -l app="$DEPLOY" --no-headers 2>/dev/null | wc -l | tr -d ' ')"
[[ "$POD_COUNT" -ge 1 ]] || fail "No pods found for deployment '$DEPLOY'"

BAD_PODS="$(kubectl -n "$NS" get pods -l app="$DEPLOY" -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.priorityClassName}{"\n"}{end}' \
  | awk -F'\t' -v want="$PC" '$2 != want { print $1 }' || true)"

if [[ -n "${BAD_PODS:-}" ]]; then
  fail "Some pods are not using '$PC': ${BAD_PODS}"
fi

pass "PriorityClass value is correct (expected $EXPECTED), deployment patched, and pods use '$PC'."
