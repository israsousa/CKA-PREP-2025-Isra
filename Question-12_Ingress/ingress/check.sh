#!/usr/bin/env bash
# check.sh — Ingress Resource Lab Validator (Spec-based, Exam Style)
set -euo pipefail

NS="echo-sound"
DEPLOY="echo"
SVC="echo-service"
ING="echo"
HOST="example.org"
PATH_PREFIX="/echo"
PORT=8080
EXPECTED_CLASS="nginx"

green() { printf "\e[32m%s\e[0m\n" "$1"; }
red()   { printf "\e[31m%s\e[0m\n" "$1"; }

fail() { red "FAIL: $*"; exit 1; }
pass() { green "PASS: $*"; }

echo "=== CHECK: Ingress Resource (Exam Mode) ==="

# Namespace
kubectl get ns "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found"

# Deployment
kubectl -n "$NS" get deploy "$DEPLOY" >/dev/null 2>&1 || fail "Deployment '$DEPLOY' not found in '$NS'"

# Service
kubectl -n "$NS" get svc "$SVC" >/dev/null 2>&1 || fail "Service '$SVC' not found in '$NS'"

SVC_PORT="$(kubectl -n "$NS" get svc "$SVC" -o jsonpath='{.spec.ports[0].port}')"
[[ "$SVC_PORT" == "$PORT" ]] || fail "Service '$SVC' port must be $PORT (found: $SVC_PORT)"

# Ingress existence
kubectl -n "$NS" get ingress "$ING" >/dev/null 2>&1 || fail "Ingress '$ING' not found in '$NS'"

# IngressClass
ING_CLASS="$(kubectl -n "$NS" get ingress "$ING" -o jsonpath='{.spec.ingressClassName}')"
[[ -n "$ING_CLASS" ]] || fail "ingressClassName not defined"
[[ "$ING_CLASS" == "$EXPECTED_CLASS" ]] || fail "ingressClassName must be '$EXPECTED_CLASS' (found: $ING_CLASS)"

# Host validation
ING_HOSTS="$(kubectl -n "$NS" get ingress "$ING" -o jsonpath='{.spec.rules[*].host}')"
echo "$ING_HOSTS" | grep -qw "$HOST" || fail "Ingress does not have host '$HOST'"

# Path validation
ING_PATH="$(kubectl -n "$NS" get ingress "$ING" -o jsonpath='{.spec.rules[?(@.host=="'"$HOST"'")].http.paths[*].path}')"
echo "$ING_PATH" | tr ' ' '\n' | grep -qx "$PATH_PREFIX" || fail "Ingress does not have path '$PATH_PREFIX'"

# pathType validation
PATH_TYPE="$(kubectl -n "$NS" get ingress "$ING" -o jsonpath='{.spec.rules[?(@.host=="'"$HOST"'")].http.paths[?(@.path=="'"$PATH_PREFIX"'")].pathType}')"
[[ -n "$PATH_TYPE" ]] || fail "pathType missing for '$PATH_PREFIX'"
[[ "$PATH_TYPE" == "Prefix" || "$PATH_TYPE" == "Exact" || "$PATH_TYPE" == "ImplementationSpecific" ]] || fail "Invalid pathType '$PATH_TYPE'"

# Backend service validation
BACKEND_SVC="$(kubectl -n "$NS" get ingress "$ING" -o jsonpath='{.spec.rules[?(@.host=="'"$HOST"'")].http.paths[?(@.path=="'"$PATH_PREFIX"'")].backend.service.name}')"
[[ "$BACKEND_SVC" == "$SVC" ]] || fail "Backend service must be '$SVC' (found: $BACKEND_SVC)"

# Backend port validation
BACKEND_PORT="$(kubectl -n "$NS" get ingress "$ING" -o jsonpath='{.spec.rules[?(@.host=="'"$HOST"'")].http.paths[?(@.path=="'"$PATH_PREFIX"'")].backend.service.port.number}')"
[[ "$BACKEND_PORT" == "$PORT" ]] || fail "Backend port must be $PORT (found: $BACKEND_PORT)"

pass "Ingress spec is correctly configured (Exam-style validation). - During the Exame you should test CURL 'curl -o /dev/null -s -w ""%{http_code}\n http://example.org/echo' - Expected HTTP 200 from http://example.org/echo"
