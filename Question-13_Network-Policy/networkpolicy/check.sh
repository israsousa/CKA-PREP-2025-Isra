#!/usr/bin/env bash
# check.sh — NetworkPolicy Validator (PASS/FAIL)
set -euo pipefail

FRONT_NS="frontend"
BACK_NS="backend"

POL="frontend-to-backend"
BACK_SVC="backend-svc"
BACK_PORT="8080"

green() { printf "\e[32m%s\e[0m\n" "$1"; }
red()   { printf "\e[31m%s\e[0m\n" "$1"; }

fail() { red "FAIL: $*"; exit 1; }
pass() { green "PASS: $*"; }

echo "=== CHECK: NetworkPolicy (Least Privilege) ==="

kubectl get ns "$FRONT_NS" >/dev/null 2>&1 || fail "Namespace $FRONT_NS not found"
kubectl get ns "$BACK_NS"  >/dev/null 2>&1 || fail "Namespace $BACK_NS not found"

kubectl -n "$FRONT_NS" get deploy frontend >/dev/null 2>&1 || fail "Deployment frontend not found in $FRONT_NS"
kubectl -n "$BACK_NS"  get deploy backend  >/dev/null 2>&1 || fail "Deployment backend not found in $BACK_NS"
kubectl -n "$BACK_NS"  get svc "$BACK_SVC" >/dev/null 2>&1 || fail "Service $BACK_SVC not found in $BACK_NS"

kubectl -n "$BACK_NS" get networkpolicy "$POL" >/dev/null 2>&1 || fail "NetworkPolicy $POL not found in $BACK_NS"

# ---- Spec checks (must be least permissive) ----
POL_TYPES="$(kubectl -n "$BACK_NS" get netpol "$POL" -o jsonpath='{.spec.policyTypes[*]}')"
echo "$POL_TYPES" | grep -qw "Ingress" || fail "policyTypes must include Ingress"

BACK_SELECTOR="$(kubectl -n "$BACK_NS" get netpol "$POL" -o jsonpath='{.spec.podSelector.matchLabels.app}')"
[[ "$BACK_SELECTOR" == "backend" ]] || fail "podSelector must target backend pods (matchLabels: app=backend)"

# Must have exactly TCP 8080 in allowed ports somewhere
PORTS_OK="$(kubectl -n "$BACK_NS" get netpol "$POL" -o jsonpath='{range .spec.ingress[*].ports[*]}{.protocol}:{.port}{"\n"}{end}' | grep -E '^TCP:8080$' || true)"
[[ -n "$PORTS_OK" ]] || fail "ingress ports must allow only TCP 8080 (missing TCP:8080)"

# Must allow from frontend namespace and frontend pods
NS_FROM_OK="$(kubectl -n "$BACK_NS" get netpol "$POL" -o jsonpath='{range .spec.ingress[*].from[*]}{.namespaceSelector.matchLabels.kubernetes\.io/metadata\.name}{"\n"}{end}' | grep -x "frontend" || true)"
[[ -n "$NS_FROM_OK" ]] || fail "ingress.from must include namespaceSelector for frontend namespace"

POD_FROM_OK="$(kubectl -n "$BACK_NS" get netpol "$POL" -o jsonpath='{range .spec.ingress[*].from[*]}{.podSelector.matchLabels.app}{"\n"}{end}' | grep -x "frontend" || true)"
[[ -n "$POD_FROM_OK" ]] || fail "ingress.from must include podSelector matchLabels app=frontend"

# ---- Runtime checks (frontend allowed, others denied) ----
echo "==> Ensuring test pods exist..."

# frontend tester
if ! kubectl -n "$FRONT_NS" get pod fe-tester >/dev/null 2>&1; then
  kubectl -n "$FRONT_NS" run fe-tester --image=curlimages/curl:8.5.0 --restart=Never --command -- /bin/sh -c "sleep 360000" >/dev/null
fi

# default namespace tester (represents "not allowed")
if ! kubectl get pod other-tester >/dev/null 2>&1; then
  kubectl run other-tester --image=curlimages/curl:8.5.0 --restart=Never --command -- /bin/sh -c "sleep 360000" >/dev/null
fi

kubectl -n "$FRONT_NS" wait --for=condition=Ready pod/fe-tester --timeout=90s >/dev/null || fail "fe-tester not Ready"
kubectl wait --for=condition=Ready pod/other-tester --timeout=90s >/dev/null || fail "other-tester not Ready"

TARGET="http://${BACK_SVC}.${BACK_NS}.svc.cluster.local:${BACK_PORT}"

echo "==> Testing allowed path: frontend -> backend:8080"
set +e
kubectl -n "$FRONT_NS" exec fe-tester -- curl -sS --max-time 3 "$TARGET" >/dev/null
RC_ALLOW=$?
set -e
[[ $RC_ALLOW -eq 0 ]] || fail "frontend could NOT reach backend on TCP 8080"

echo "==> Testing denied path: default -> backend:8080 (should FAIL)"
set +e
kubectl exec other-tester -- curl -sS --max-time 3 "$TARGET" >/dev/null
RC_DENY=$?
set -e
[[ $RC_DENY -ne 0 ]] || fail "non-frontend pod unexpectedly reached backend (policy not least-privilege or not enforced)"

pass "NetworkPolicy is correct: only frontend namespace/pods can reach backend on TCP 8080; all other ingress denied."
