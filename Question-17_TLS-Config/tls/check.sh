#!/usr/bin/env bash
# check.sh — TLS Question Validator (PASS/FAIL)
set -euo pipefail

NS="nginx-static"
APP="nginx-static"
CM="nginx-config"
HOST="codegenitor.k8s.local"

green() { printf "\e[32m%s\e[0m\n" "$1"; }
red()   { printf "\e[31m%s\e[0m\n" "$1"; }

fail() { red "FAIL: $*"; exit 1; }
pass() { green "PASS: $*"; }

echo "=== CHECK: TLS Configuration ==="

kubectl get ns "$NS" >/dev/null 2>&1 || fail "Namespace $NS not found"
kubectl -n "$NS" get deploy "$APP" >/dev/null 2>&1 || fail "Deployment $APP not found"
kubectl -n "$NS" get cm "$CM" >/dev/null 2>&1 || fail "ConfigMap $CM not found"
kubectl -n "$NS" get svc "$APP" >/dev/null 2>&1 || fail "Service $APP not found"

SVC_IP="$(kubectl -n "$NS" get svc "$APP" -o jsonpath='{.spec.clusterIP}')"
[[ -n "$SVC_IP" && "$SVC_IP" != "None" ]] || fail "Service has no ClusterIP"

CONF="$(kubectl -n "$NS" get cm "$CM" -o jsonpath='{.data.nginx\.conf}')"

# Ignore comment lines for config validation
CONF_NOCOMMENTS="$(printf "%s\n" "$CONF" | sed '/^[[:space:]]*#/d')"

# Must have ssl_protocols directive
echo "$CONF_NOCOMMENTS" | grep -qE '^[[:space:]]*ssl_protocols[[:space:]]+.*;' \
  || fail "ConfigMap does not contain an ssl_protocols directive"

# Must include TLSv1.3 in ssl_protocols directive
echo "$CONF_NOCOMMENTS" | grep -qE '^[[:space:]]*ssl_protocols[[:space:]]+.*TLSv1\.3.*;' \
  || fail "ssl_protocols does not include TLSv1.3"

# Must NOT include TLSv1.2 in ssl_protocols directive
echo "$CONF_NOCOMMENTS" | grep -qE '^[[:space:]]*ssl_protocols[[:space:]]+.*TLSv1\.2.*;' \
  && fail "ssl_protocols still includes TLSv1.2"

grep -qE "^${SVC_IP}[[:space:]]+${HOST}([[:space:]]|\$)" /etc/hosts \
  || fail "/etc/hosts missing correct mapping: ${SVC_IP} ${HOST}"

set +e
curl --tls-max 1.2 "https://${HOST}" -k >/dev/null 2>&1
RC_TLS12=$?
curl --tlsv1.3 "https://${HOST}" -k >/dev/null 2>&1
RC_TLS13=$?
set -e

[[ $RC_TLS12 -ne 0 ]] || fail "TLSv1.2 unexpectedly worked (curl --tls-max 1.2 returned 0)"
[[ $RC_TLS13 -eq 0 ]] || fail "TLSv1.3 did not work (curl --tlsv1.3 returned non-zero)"

pass "TLSv1.2 blocked, TLSv1.3 works, hosts mapping is correct."
