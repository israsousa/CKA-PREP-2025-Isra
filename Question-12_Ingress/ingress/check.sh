#!/usr/bin/env bash
# check.sh — Ingress Resource Lab Validator (PASS/FAIL)
set -euo pipefail

NS="echo-sound"
DEPLOY="echo"
SVC="echo-service"
ING="echo"
HOST="example.org"
PATH_PREFIX="/echo"
PORT=8080

green() { printf "\e[32m%s\e[0m\n" "$1"; }
red()   { printf "\e[31m%s\e[0m\n" "$1"; }

fail() { red "FAIL: $*"; exit 1; }
pass() { green "PASS: $*"; }

echo "=== CHECK: Ingress Resource ==="

kubectl get ns "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found"
kubectl -n "$NS" get deploy "$DEPLOY" >/dev/null 2>&1 || fail "Deployment '$DEPLOY' not found in '$NS'"
kubectl -n "$NS" get svc "$SVC" >/dev/null 2>&1 || fail "Service '$SVC' not found in '$NS'"
kubectl -n "$NS" get ingress "$ING" >/dev/null 2>&1 || fail "Ingress '$ING' not found in '$NS'"

SVC_TYPE="$(kubectl -n "$NS" get svc "$SVC" -o jsonpath='{.spec.type}')"
[[ "$SVC_TYPE" == "NodePort" ]] || fail "Service '$SVC' must be NodePort (found: $SVC_TYPE)"

SVC_PORT="$(kubectl -n "$NS" get svc "$SVC" -o jsonpath='{.spec.ports[0].port}')"
[[ "$SVC_PORT" == "$PORT" ]] || fail "Service '$SVC' port must be $PORT (found: $SVC_PORT)"

ING_HOSTS="$(kubectl -n "$NS" get ingress "$ING" -o jsonpath='{.spec.rules[*].host}')"
echo "$ING_HOSTS" | grep -qw "$HOST" || fail "Ingress does not have host '$HOST'"

ING_PATH="$(kubectl -n "$NS" get ingress "$ING" -o jsonpath='{.spec.rules[?(@.host=="'"$HOST"'")].http.paths[*].path}')"
echo "$ING_PATH" | tr ' ' '\n' | grep -qx "$PATH_PREFIX" || fail "Ingress does not have path '$PATH_PREFIX' for host '$HOST'"

PATH_TYPE="$(kubectl -n "$NS" get ingress "$ING" -o jsonpath='{.spec.rules[?(@.host=="'"$HOST"'")].http.paths[?(@.path=="'"$PATH_PREFIX"'")].pathType}')"
[[ -n "$PATH_TYPE" ]] || fail "Ingress pathType missing for '$PATH_PREFIX'"
[[ "$PATH_TYPE" == "Prefix" || "$PATH_TYPE" == "Exact" || "$PATH_TYPE" == "ImplementationSpecific" ]] || fail "Invalid pathType '$PATH_TYPE'"

BACKEND_SVC="$(kubectl -n "$NS" get ingress "$ING" -o jsonpath='{.spec.rules[?(@.host=="'"$HOST"'")].http.paths[?(@.path=="'"$PATH_PREFIX"'")].backend.service.name}')"
[[ "$BACKEND_SVC" == "$SVC" ]] || fail "Ingress backend service must be '$SVC' (found: $BACKEND_SVC)"

BACKEND_PORT="$(kubectl -n "$NS" get ingress "$ING" -o jsonpath='{.spec.rules[?(@.host=="'"$HOST"'")].http.paths[?(@.path=="'"$PATH_PREFIX"'")].backend.service.port.number}')"
[[ "$BACKEND_PORT" == "$PORT" ]] || fail "Ingress backend port must be $PORT (found: $BACKEND_PORT)"

echo "==> Runtime check (curl) ..."
set +e
HTTP_CODE="$(curl -o /dev/null -s -w "%{http_code}" "http://${HOST}${PATH_PREFIX}")"
RC=$?
set -e

[[ $RC -eq 0 ]] || fail "curl failed (rc=$RC). Ensure '${HOST}' resolves in your environment."
[[ "$HTTP_CODE" == "200" ]] || fail "Expected HTTP 200 from http://${HOST}${PATH_PREFIX} but got ${HTTP_CODE}"

pass "Ingress routes http://${HOST}${PATH_PREFIX} to ${SVC}:${PORT} and returns 200."
