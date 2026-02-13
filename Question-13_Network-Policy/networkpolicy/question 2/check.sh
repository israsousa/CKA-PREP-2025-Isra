#!/usr/bin/env bash
# check.sh — Validates least-privilege NetPol solution
set -euo pipefail

NETPOLDIR="${HOME}/netpol"

green() { printf "\e[32m%s\e[0m\n" "$1"; }
red()   { printf "\e[31m%s\e[0m\n" "$1"; }

fail() { red "❌ $*"; exit 1; }
pass() { green "✅ $*"; }

echo "=== CHECK: NetworkPolicy Frontend -> Backend (least privilege) ==="

command -v kubectl >/dev/null 2>&1 || fail "kubectl not found"
[[ -d "${NETPOLDIR}" ]] || fail "Expected folder not found: ${NETPOLDIR}"

# Ensure deny-all policies still exist
kubectl -n backend get netpol deny-all-ingress >/dev/null 2>&1 || fail "deny-all-ingress missing in backend (do not delete it)"
kubectl -n backend get netpol deny-all-egress  >/dev/null 2>&1 || fail "deny-all-egress missing in backend (do not delete it)"
pass "Deny-all NetworkPolicies still present."

# Identify pods
FRONT_POD="$(kubectl -n frontend get pod -l app=frontend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
BACK_POD="$(kubectl -n backend  get pod -l app=backend  -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
OTHER_POD="$(kubectl -n other    get pod -l app=other-client -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"

[[ -n "${FRONT_POD}" ]] || fail "frontend pod not found"
[[ -n "${BACK_POD}"  ]] || fail "backend pod not found"
[[ -n "${OTHER_POD}" ]] || fail "other-client pod not found"

# Check that some allow policy exists targeting backend pods
ALLOW_POLICIES="$(kubectl -n backend get netpol -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | grep -v '^deny-all-' || true)"
[[ -n "${ALLOW_POLICIES}" ]] || fail "No additional NetworkPolicy found in backend. You must apply ONE from ${NETPOLDIR}"
pass "Found non-deny NetworkPolicy in backend: $(echo "${ALLOW_POLICIES}" | tr '\n' ' ')"

# Validate least-privilege shape: must select app=backend (not all pods)
# and must restrict from frontend namespace + frontend pods and port 8080.
# We'll assert at least one policy meets these constraints.
MEETS=0
for NP in ${ALLOW_POLICIES}; do
  yaml="$(kubectl -n backend get netpol "${NP}" -o yaml)"

  echo "${yaml}" | grep -q "namespace: backend" || continue
  echo "${yaml}" | grep -q "app: backend" || continue
  echo "${yaml}" | grep -q "kubernetes.io/metadata.name: frontend" || continue
  echo "${yaml}" | grep -q "app: frontend" || continue
  echo "${yaml}" | grep -q "port: 8080" || continue

  # ensure it's not podSelector: {}
  echo "${yaml}" | grep -q "podSelector: {}" && continue

  MEETS=1
  GOOD_NP="${NP}"
  break
done

[[ "${MEETS}" -eq 1 ]] || fail "No applied NetworkPolicy matches least-privilege requirements (backend pods only, from frontend ns+pods, port 8080)."
pass "Least-privilege policy detected: ${GOOD_NP}"

echo "==> Functional test: frontend -> backend should succeed"
# Use short timeout so failures return fast
set +e
out_front="$(kubectl -n frontend exec "${FRONT_POD}" -- curl -sS --max-time 3 http://backend.backend.svc.cluster.local:8080 2>&1)"
rc_front=$?
set -e
[[ $rc_front -eq 0 ]] || fail "frontend -> backend FAILED. curl output: ${out_front}"
echo "${out_front}" | grep -q "backend-ok" || fail "frontend -> backend did not return expected response. Got: ${out_front}"
pass "frontend -> backend works."

echo "==> Negative test: other namespace -> backend should fail (blocked)"
set +e
out_other="$(kubectl -n other exec "${OTHER_POD}" -- curl -sS --max-time 3 http://backend.backend.svc.cluster.local:8080 2>&1)"
rc_other=$?
set -e

# We expect failure (timeout / connection error). If it succeeds and returns backend-ok, it's too permissive.
if [[ $rc_other -eq 0 ]] && echo "${out_other}" | grep -q "backend-ok"; then
  fail "other -> backend unexpectedly succeeded. Your policy is too permissive."
fi
pass "other -> backend is blocked (least privilege holds)."

echo
pass "All checks passed."
echo "You implemented least-privilege frontend -> backend connectivity without touching deny-all policies."
