#!/usr/bin/env bash
# check.sh — Resource Requests/Limits validation (codegenitor)
set -euo pipefail

# ----- Colors -----
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
NC="\033[0m" # No Color

pass() { echo -e "${GREEN}PASS:${NC} $*"; }
fail() { echo -e "${RED}FAIL:${NC} $*"; exit 1; }
warn() { echo -e "${YELLOW}WARN:${NC} $*"; }

NS="default"
DEPLOY="wordpress"
EXPECTED_REPLICAS="3"

echo "=== CHECK: Resource Requests/Limits (codegenitor) ==="

# 1) Deployment exists
kubectl get deploy "$DEPLOY" -n "$NS" >/dev/null 2>&1 || fail "Deployment '$DEPLOY' not found in namespace '$NS'"

# 2) Replicas back to 3 and ready
REPLICAS="$(kubectl get deploy "$DEPLOY" -n "$NS" -o jsonpath='{.spec.replicas}')"
READY_REPLICAS="$(kubectl get deploy "$DEPLOY" -n "$NS" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || true)"
READY_REPLICAS="${READY_REPLICAS:-0}"

[[ "$REPLICAS" == "$EXPECTED_REPLICAS" ]] || fail "Deployment '$DEPLOY' replicas is '$REPLICAS' (expected '$EXPECTED_REPLICAS')"
[[ "$READY_REPLICAS" == "$EXPECTED_REPLICAS" ]] || fail "Deployment '$DEPLOY' readyReplicas is '$READY_REPLICAS' (expected '$EXPECTED_REPLICAS'). Try: kubectl rollout status deploy/$DEPLOY -n $NS"

pass "Deployment '$DEPLOY' has replicas=$REPLICAS and readyReplicas=$READY_REPLICAS"

# 3) Must have initContainer + main container
INIT_NAME="$(kubectl get deploy "$DEPLOY" -n "$NS" -o jsonpath='{.spec.template.spec.initContainers[0].name}' 2>/dev/null || true)"
MAIN_NAME="$(kubectl get deploy "$DEPLOY" -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].name}' 2>/dev/null || true)"

[[ -n "$INIT_NAME" ]] || fail "No initContainer found on deployment '$DEPLOY' (expected at least 1)"
[[ -n "$MAIN_NAME" ]] || fail "No main container found on deployment '$DEPLOY' (expected at least 1)"

pass "Found initContainer='$INIT_NAME' and container='$MAIN_NAME'"

# 4) Extract resources for BOTH (cpu+mem requests+limits)
INIT_CPU_REQ="$(kubectl get deploy "$DEPLOY" -n "$NS" -o jsonpath='{.spec.template.spec.initContainers[0].resources.requests.cpu}' 2>/dev/null || true)"
INIT_MEM_REQ="$(kubectl get deploy "$DEPLOY" -n "$NS" -o jsonpath='{.spec.template.spec.initContainers[0].resources.requests.memory}' 2>/dev/null || true)"
INIT_CPU_LIM="$(kubectl get deploy "$DEPLOY" -n "$NS" -o jsonpath='{.spec.template.spec.initContainers[0].resources.limits.cpu}' 2>/dev/null || true)"
INIT_MEM_LIM="$(kubectl get deploy "$DEPLOY" -n "$NS" -o jsonpath='{.spec.template.spec.initContainers[0].resources.limits.memory}' 2>/dev/null || true)"

MAIN_CPU_REQ="$(kubectl get deploy "$DEPLOY" -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}' 2>/dev/null || true)"
MAIN_MEM_REQ="$(kubectl get deploy "$DEPLOY" -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}' 2>/dev/null || true)"
MAIN_CPU_LIM="$(kubectl get deploy "$DEPLOY" -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}' 2>/dev/null || true)"
MAIN_MEM_LIM="$(kubectl get deploy "$DEPLOY" -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}' 2>/dev/null || true)"

# 5) Ensure all values are set (not empty)
[[ -n "$INIT_CPU_REQ" && -n "$INIT_MEM_REQ" && -n "$INIT_CPU_LIM" && -n "$INIT_MEM_LIM" ]] \
  || fail "initContainer '$INIT_NAME' missing resources. req(cpu='${INIT_CPU_REQ:-}', mem='${INIT_MEM_REQ:-}') lim(cpu='${INIT_CPU_LIM:-}', mem='${INIT_MEM_LIM:-}')"

[[ -n "$MAIN_CPU_REQ" && -n "$MAIN_MEM_REQ" && -n "$MAIN_CPU_LIM" && -n "$MAIN_MEM_LIM" ]] \
  || fail "container '$MAIN_NAME' missing resources. req(cpu='${MAIN_CPU_REQ:-}', mem='${MAIN_MEM_REQ:-}') lim(cpu='${MAIN_CPU_LIM:-}', mem='${MAIN_MEM_LIM:-}')"

pass "Both init + main have requests/limits set"

# 6) Ensure init == main exactly (strict exam requirement)
if [[ "$INIT_CPU_REQ" != "$MAIN_CPU_REQ" || "$INIT_MEM_REQ" != "$MAIN_MEM_REQ" || "$INIT_CPU_LIM" != "$MAIN_CPU_LIM" || "$INIT_MEM_LIM" != "$MAIN_MEM_LIM" ]]; then
  fail "initContainer and main container resources do NOT match exactly:
  init: req(cpu=$INIT_CPU_REQ mem=$INIT_MEM_REQ) lim(cpu=$INIT_CPU_LIM mem=$INIT_MEM_LIM)
  main: req(cpu=$MAIN_CPU_REQ mem=$MAIN_MEM_REQ) lim(cpu=$MAIN_CPU_LIM mem=$MAIN_MEM_LIM)"
fi

pass "Resources match exactly (init == main)"
pass "✅ ALL CHECKS PASSED"
