#!/usr/bin/env bash
# check.sh — Sidecar Container Validator (CKA style)
set -euo pipefail

NS="${NS:-default}"
DEPLOY="${DEPLOY:-wordpress}"

fail() { echo "❌ $1"; exit 1; }
pass() { echo "✅ $1"; }

echo "=== CHECK: Sidecar Container (wordpress) ==="

kubectl -n "${NS}" get deploy "${DEPLOY}" >/dev/null 2>&1 || fail "Deployment '${DEPLOY}' not found in namespace '${NS}'."

echo "==> Checking rollout status..."
kubectl -n "${NS}" rollout status deploy/"${DEPLOY}" --timeout=120s >/dev/null 2>&1 || fail "Deployment rollout not successful."

POD="$(kubectl -n "${NS}" get pod -l app=wordpress -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
[[ -n "${POD}" ]] || fail "No wordpress pod found."

echo "==> Using pod: ${POD}"

echo "==> Checking there is NO sidecar in initContainers..."
init_names="$(kubectl -n "${NS}" get pod "${POD}" -o jsonpath='{.spec.initContainers[*].name}' 2>/dev/null || true)"
if echo "${init_names}" | grep -qw sidecar; then
  fail "Found 'sidecar' in initContainers. Sidecar must be a normal container, not an initContainer."
fi
pass "Sidecar is not an initContainer."

echo "==> Checking containers include wordpress + sidecar..."
containers="$(kubectl -n "${NS}" get pod "${POD}" -o jsonpath='{.spec.containers[*].name}')"
echo "Containers: ${containers}"
echo "${containers}" | grep -qw wordpress || fail "Main container 'wordpress' not found."
echo "${containers}" | grep -qw sidecar   || fail "Sidecar container 'sidecar' not found."
pass "Both containers present."

echo "==> Checking sidecar image is busybox:stable..."
sidecar_image="$(kubectl -n "${NS}" get pod "${POD}" -o jsonpath='{range .spec.containers[?(@.name=="sidecar")]}{.image}{end}')"
[[ "${sidecar_image}" == "busybox:stable" ]] || fail "Sidecar image must be 'busybox:stable' but got '${sidecar_image}'."
pass "Sidecar image is correct."

echo "==> Checking sidecar command tails /var/log/wordpress.log..."
sidecar_cmd="$(kubectl -n "${NS}" get pod "${POD}" -o jsonpath='{range .spec.containers[?(@.name=="sidecar")]}{.command}{" "}{.args}{end}')"
echo "Sidecar command/args: ${sidecar_cmd}"
echo "${sidecar_cmd}" | grep -q "tail" || fail "Sidecar does not appear to run 'tail'."
echo "${sidecar_cmd}" | grep -q "/var/log/wordpress.log" || fail "Sidecar is not tailing /var/log/wordpress.log."
pass "Sidecar command looks correct."

echo "==> Checking both containers mount the SAME volume at /var/log..."
sidecar_vol="$(kubectl -n "${NS}" get pod "${POD}" -o jsonpath='{range .spec.containers[?(@.name=="sidecar")].volumeMounts[?(@.mountPath=="/var/log")]}{.name}{end}')"
[[ -n "${sidecar_vol}" ]] || fail "Sidecar does not have a volumeMount at /var/log."

main_vol="$(kubectl -n "${NS}" get pod "${POD}" -o jsonpath='{range .spec.containers[?(@.name=="wordpress")].volumeMounts[?(@.mountPath=="/var/log")]}{.name}{end}')"
[[ -n "${main_vol}" ]] || fail "Main container does not have a volumeMount at /var/log."

[[ "${main_vol}" == "${sidecar_vol}" ]] || fail "Main and sidecar are not using the same volume for /var/log. main=${main_vol}, sidecar=${sidecar_vol}."
pass "Both containers share the same /var/log volume (${main_vol})."

echo "==> Checking the referenced volume exists in the pod spec..."
kubectl -n "${NS}" get pod "${POD}" -o jsonpath="{range .spec.volumes[?(@.name==\"${main_vol}\")]}{.name}{end}" | grep -q "${main_vol}" \
  || fail "Volume '${main_vol}' referenced by mounts does not exist in pod spec."
pass "Volume exists in pod spec."

echo "==> Functional test: write a unique line to the log and confirm sidecar outputs it..."
test_line="CHECK-$(date +%s)"
kubectl -n "${NS}" exec "${POD}" -c wordpress -- sh -c "echo '${test_line}' >> /var/log/wordpress.log" >/dev/null 2>&1 \
  || fail "Failed to write to /var/log/wordpress.log from main container."

sleep 2

kubectl -n "${NS}" logs "${POD}" -c sidecar --tail=100 | grep -q "${test_line}" \
  && pass "Sidecar is tailing the log (found '${test_line}')." \
  || fail "Sidecar logs did not include the expected test line '${test_line}'."

echo
pass "All checks passed."
