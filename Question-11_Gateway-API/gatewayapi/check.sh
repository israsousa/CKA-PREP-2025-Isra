#!/usr/bin/env bash
# check.sh — Gateway API Migration Check (Codegenitor)
set -euo pipefail

GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
NC="\033[0m"

pass() { echo -e "${GREEN}PASS${NC}: $*"; }
fail() { echo -e "${RED}FAIL${NC}: $*"; exit 1; }
warn() { echo -e "${YELLOW}WARN${NC}: $*"; }

HOSTNAME="gateway.web.k8s.local"
GWCLASS="nginx-class"
TLS_SECRET="web-tls"
SVC_NAME="web-service"

GW_NAME="web-gateway"
ROUTE_NAME="web-route"

echo "=== CHECK: Gateway API Migration (Codegenitor) ==="

# --- Reliable CRD checks (DO NOT use api-resources grep) ---
kubectl get crd gateways.gateway.networking.k8s.io >/dev/null 2>&1 \
  && pass "CRD gateways.gateway.networking.k8s.io present" \
  || fail "Gateway API CRD 'gateways.gateway.networking.k8s.io' missing"

kubectl get crd httproutes.gateway.networking.k8s.io >/dev/null 2>&1 \
  && pass "CRD httproutes.gateway.networking.k8s.io present" \
  || fail "Gateway API CRD 'httproutes.gateway.networking.k8s.io' missing"

# --- GatewayClass ---
kubectl get gatewayclass "${GWCLASS}" >/dev/null 2>&1 \
  && pass "GatewayClass '${GWCLASS}' exists" \
  || fail "GatewayClass '${GWCLASS}' not found"

# --- Ingress source-of-truth ---
kubectl get ingress web >/dev/null 2>&1 \
  && pass "Ingress 'web' exists" \
  || fail "Ingress 'web' not found"

ING_TLS="$(kubectl get ingress web -o jsonpath='{.spec.tls[0].secretName}' 2>/dev/null || true)"
[[ -n "${ING_TLS}" ]] || fail "Ingress 'web' has no TLS configured"
[[ "${ING_TLS}" == "${TLS_SECRET}" ]] \
  && pass "Ingress TLS secret is '${TLS_SECRET}'" \
  || fail "Ingress TLS secret is '${ING_TLS}', expected '${TLS_SECRET}'"

# --- Gateway exists + spec validation ---
kubectl get gateway "${GW_NAME}" >/dev/null 2>&1 \
  && pass "Gateway '${GW_NAME}' exists" \
  || fail "Gateway '${GW_NAME}' not found"

GW_CLASS="$(kubectl get gateway "${GW_NAME}" -o jsonpath='{.spec.gatewayClassName}')"
[[ "${GW_CLASS}" == "${GWCLASS}" ]] \
  && pass "GatewayClassName is '${GWCLASS}'" \
  || fail "GatewayClassName is '${GW_CLASS}', expected '${GWCLASS}'"

GW_PROTOCOL="$(kubectl get gateway "${GW_NAME}" -o jsonpath='{.spec.listeners[0].protocol}')"
GW_PORT="$(kubectl get gateway "${GW_NAME}" -o jsonpath='{.spec.listeners[0].port}')"
GW_HOST="$(kubectl get gateway "${GW_NAME}" -o jsonpath='{.spec.listeners[0].hostname}')"
GW_TLS_MODE="$(kubectl get gateway "${GW_NAME}" -o jsonpath='{.spec.listeners[0].tls.mode}')"
GW_CERT_SECRET="$(kubectl get gateway "${GW_NAME}" -o jsonpath='{.spec.listeners[0].tls.certificateRefs[0].name}')"

[[ "${GW_PROTOCOL}" == "HTTPS" ]] && pass "Gateway listener protocol HTTPS" || fail "Gateway protocol '${GW_PROTOCOL}', expected HTTPS"
[[ "${GW_PORT}" == "443" ]] && pass "Gateway listener port 443" || fail "Gateway port '${GW_PORT}', expected 443"
[[ "${GW_HOST}" == "${HOSTNAME}" ]] && pass "Gateway hostname '${HOSTNAME}'" || fail "Gateway hostname '${GW_HOST}', expected '${HOSTNAME}'"
[[ "${GW_TLS_MODE}" == "Terminate" ]] && pass "Gateway TLS mode Terminate" || fail "Gateway TLS mode '${GW_TLS_MODE}', expected Terminate"
[[ "${GW_CERT_SECRET}" == "${TLS_SECRET}" ]] && pass "Gateway cert secret '${TLS_SECRET}'" || fail "Gateway cert secret '${GW_CERT_SECRET}', expected '${TLS_SECRET}'"

# --- Controller status hint (don’t fail exam-style, just warn) ---
GW_ACCEPTED="$(kubectl get gateway "${GW_NAME}" -o jsonpath='{.status.conditions[?(@.type=="Accepted")].status}' 2>/dev/null || true)"
GW_PROGRAMMED="$(kubectl get gateway "${GW_NAME}" -o jsonpath='{.status.conditions[?(@.type=="Programmed")].status}' 2>/dev/null || true)"
if [[ "${GW_ACCEPTED}" != "True" || "${GW_PROGRAMMED}" != "True" ]]; then
  warn "Gateway status not fully ready yet (Accepted=${GW_ACCEPTED:-?}, Programmed=${GW_PROGRAMMED:-?})."
  warn "This usually means: Gateway controller not running/installed. In exam labs it will be."
else
  pass "Gateway status is ready (Accepted=True, Programmed=True)"
fi

# --- HTTPRoute exists + spec validation ---
kubectl get httproute "${ROUTE_NAME}" >/dev/null 2>&1 \
  && pass "HTTPRoute '${ROUTE_NAME}' exists" \
  || fail "HTTPRoute '${ROUTE_NAME}' not found"

ROUTE_PARENT="$(kubectl get httproute "${ROUTE_NAME}" -o jsonpath='{.spec.parentRefs[0].name}')"
[[ "${ROUTE_PARENT}" == "${GW_NAME}" ]] \
  && pass "HTTPRoute parentRefs -> '${GW_NAME}'" \
  || fail "HTTPRoute parentRefs -> '${ROUTE_PARENT}', expected '${GW_NAME}'"

ROUTE_HOST="$(kubectl get httproute "${ROUTE_NAME}" -o jsonpath='{.spec.hostnames[0]}')"
[[ "${ROUTE_HOST}" == "${HOSTNAME}" ]] \
  && pass "HTTPRoute hostname '${HOSTNAME}'" \
  || fail "HTTPRoute hostname '${ROUTE_HOST}', expected '${HOSTNAME}'"

ROUTE_PATH_TYPE="$(kubectl get httproute "${ROUTE_NAME}" -o jsonpath='{.spec.rules[0].matches[0].path.type}')"
ROUTE_PATH_VAL="$(kubectl get httproute "${ROUTE_NAME}" -o jsonpath='{.spec.rules[0].matches[0].path.value}')"
[[ "${ROUTE_PATH_TYPE}" == "PathPrefix" ]] && pass "HTTPRoute path type PathPrefix" || fail "HTTPRoute path type '${ROUTE_PATH_TYPE}', expected PathPrefix"
[[ "${ROUTE_PATH_VAL}" == "/" ]] && pass "HTTPRoute path value '/'" || fail "HTTPRoute path value '${ROUTE_PATH_VAL}', expected '/'"

ROUTE_BACKEND_NAME="$(kubectl get httproute "${ROUTE_NAME}" -o jsonpath='{.spec.rules[0].backendRefs[0].name}')"
ROUTE_BACKEND_PORT="$(kubectl get httproute "${ROUTE_NAME}" -o jsonpath='{.spec.rules[0].backendRefs[0].port}')"
[[ "${ROUTE_BACKEND_NAME}" == "${SVC_NAME}" ]] && pass "HTTPRoute backend service '${SVC_NAME}'" || fail "HTTPRoute backend service '${ROUTE_BACKEND_NAME}', expected '${SVC_NAME}'"
[[ "${ROUTE_BACKEND_PORT}" == "80" ]] && pass "HTTPRoute backend port 80" || fail "HTTPRoute backend port '${ROUTE_BACKEND_PORT}', expected 80"

echo
echo -e "${GREEN}✅ ALL REQUIRED CHECKS PASSED${NC}"
