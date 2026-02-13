#!/usr/bin/env bash
# check.sh — NodePort Question Validator (PASS/FAIL)
set -euo pipefail

NS="default"
DEP="nodeport-deployment"
SVC="nodeport-service"

green() { printf "\e[32m%s\e[0m\n" "$1"; }
red()   { printf "\e[31m%s\e[0m\n" "$1"; }
fail()  { red "FAIL: $*"; exit 1; }
pass()  { green "PASS: $*"; }

echo "=== CHECK: NodePort Service Exposure ==="

# --- Existence checks
kubectl get ns "${NS}" >/dev/null 2>&1 || fail "Namespace ${NS} not found"
kubectl -n "${NS}" get deploy "${DEP}" >/dev/null 2>&1 || fail "Deployment ${DEP} not found"
kubectl -n "${NS}" get svc "${SVC}" >/dev/null 2>&1 || fail "Service ${SVC} not found"

# --- Deployment checks (containerPort 80, TCP)
PORTS_JSON="$(kubectl -n "${NS}" get deploy "${DEP}" -o jsonpath='{range .spec.template.spec.containers[*]}{.name}{"|"}{range .ports[*]}{.containerPort}{"|"}{.protocol}{";"}{end}{"\n"}{end}' 2>/dev/null || true)"
echo "${PORTS_JSON}" | grep -Eq '\|80\|TCP' || fail "Deployment does not expose containerPort 80/TCP (set spec.template.spec.containers[].ports[].containerPort=80 and protocol=TCP)"

# --- Service checks (NodePort, port 80/TCP, nodePort assigned)
SVC_TYPE="$(kubectl -n "${NS}" get svc "${SVC}" -o jsonpath='{.spec.type}')"
[[ "${SVC_TYPE}" == "NodePort" ]] || fail "Service type must be NodePort (found: ${SVC_TYPE})"

SVC_PORT="$(kubectl -n "${NS}" get svc "${SVC}" -o jsonpath='{.spec.ports[0].port}')"
[[ "${SVC_PORT}" == "80" ]] || fail "Service port must be 80 (found: ${SVC_PORT})"

SVC_PROTO="$(kubectl -n "${NS}" get svc "${SVC}" -o jsonpath='{.spec.ports[0].protocol}')"
[[ "${SVC_PROTO}" == "TCP" || -z "${SVC_PROTO}" ]] || fail "Service protocol must be TCP (found: ${SVC_PROTO})"

NODEPORT="$(kubectl -n "${NS}" get svc "${SVC}" -o jsonpath='{.spec.ports[0].nodePort}')"
[[ -n "${NODEPORT}" ]] || fail "Service has no nodePort assigned"

# --- Selector -> endpoints checks
SEL_APP="$(kubectl -n "${NS}" get svc "${SVC}" -o jsonpath='{.spec.selector.app}' 2>/dev/null || true)"
[[ -n "${SEL_APP}" ]] || fail "Service selector is missing (expected something like: spec.selector.app=nodeport-deployment)"

# Ensure at least one endpoint exists (service routes to pods)
EP_COUNT="$(kubectl -n "${NS}" get endpoints "${SVC}" -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null | wc -w | tr -d ' ')"
[[ "${EP_COUNT}" -ge 1 ]] || fail "Service has no endpoints (selector does not match any running pods)"

# --- Extra sanity: Deployment pods ready
READY="$(kubectl -n "${NS}" get deploy "${DEP}" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || true)"
[[ -n "${READY}" && "${READY}" -ge 1 ]] || fail "Deployment is not ready"

pass "Deployment exposes 80/TCP and Service ${SVC} is NodePort on port 80 routing to Pods (endpoints found)."
