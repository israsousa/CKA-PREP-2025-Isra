#!/usr/bin/env bash
set -euo pipefail

NS="codegenitor-cni"
SVC="echo-svc"

green() { printf "\e[32m%s\e[0m\n" "$1"; }
red()   { printf "\e[31m%s\e[0m\n" "$1"; }
fail()  { red "FAIL: $*"; exit 1; }
pass()  { green "PASS: $*"; }

echo "=== CHECK: CNI + NetworkPolicy Enforcement ==="

kubectl get ns "$NS" >/dev/null 2>&1 || fail "Namespace $NS not found (run ./prep.sh first)"
kubectl -n "$NS" get svc "$SVC" >/dev/null 2>&1 || fail "Service $SVC not found"
kubectl -n "$NS" get pod client-allowed >/dev/null 2>&1 || fail "Pod client-allowed not found"
kubectl -n "$NS" get pod client-denied >/dev/null 2>&1 || fail "Pod client-denied not found"

CNI_OK=0

if kubectl -n kube-system get ds 2>/dev/null | grep -qiE 'kube-flannel|flannel'; then
  CNI_OK=1
fi

if kubectl -n kube-system get ds 2>/dev/null | grep -qiE 'calico|canal'; then
  CNI_OK=1
fi

if kubectl -n kube-system get pods 2>/dev/null | grep -qiE 'calico|tigera|canal|flannel'; then
  CNI_OK=1
fi

[[ "$CNI_OK" -eq 1 ]] || fail "No CNI pods/daemonsets detected in kube-system (expected Flannel or Calico-family)"

echo "==> Applying NetworkPolicy test (deny by default, allow only access=granted)"
kubectl -n "$NS" apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-only-granted-to-echo
spec:
  podSelector:
    matchLabels:
      app: echo
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              access: granted
EOF

echo "==> Waiting a moment for policy to take effect"
sleep 3

echo "==> Test: allowed client should reach echo-svc"
kubectl -n "$NS" exec client-allowed -- sh -c "wget -qO- --timeout=3 http://${SVC}:80 >/dev/null"
RC_ALLOWED=$?
[[ "$RC_ALLOWED" -eq 0 ]] || fail "allowed client could NOT reach ${SVC} (basic connectivity or DNS issue)"

echo "==> Test: denied client should NOT reach echo-svc"
set +e
kubectl -n "$NS" exec client-denied -- sh -c "wget -qO- --timeout=3 http://${SVC}:80 >/dev/null"
RC_DENIED=$?
set -e

[[ "$RC_DENIED" -ne 0 ]] || fail "denied client CAN reach ${SVC} (NetworkPolicy not enforced by CNI)"

pass "CNI detected + NetworkPolicy enforcement works (allowed succeeds, denied blocked)."
