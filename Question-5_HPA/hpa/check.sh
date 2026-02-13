#!/usr/bin/env bash
set -euo pipefail

NS="autoscale"
DEPLOY="apache-deployment"
HPA="apache-server"

green() { printf "\e[32m%s\e[0m\n" "$1"; }
red()   { printf "\e[31m%s\e[0m\n" "$1"; }

fail() { red "FAIL: $*"; exit 1; }
pass() { green "PASS: $*"; }

echo "=== CHECK: HPA (autoscaling/v2) ==="

kubectl get ns "${NS}" >/dev/null 2>&1 || fail "Namespace '${NS}' not found"
kubectl -n "${NS}" get deploy "${DEPLOY}" >/dev/null 2>&1 || fail "Deployment '${DEPLOY}' not found"
kubectl -n "${NS}" get hpa "${HPA}" >/dev/null 2>&1 || fail "HPA '${HPA}' not found in namespace '${NS}'"

API_VERSION="$(kubectl -n "${NS}" get hpa "${HPA}" -o jsonpath='{.apiVersion}')"
KIND="$(kubectl -n "${NS}" get hpa "${HPA}" -o jsonpath='{.kind}')"

[ "${API_VERSION}" = "autoscaling/v2" ] || fail "HPA apiVersion must be autoscaling/v2 (got: ${API_VERSION})"
[ "${KIND}" = "HorizontalPodAutoscaler" ] || fail "Resource kind must be HorizontalPodAutoscaler (got: ${KIND})"

TARGET_KIND="$(kubectl -n "${NS}" get hpa "${HPA}" -o jsonpath='{.spec.scaleTargetRef.kind}')"
TARGET_NAME="$(kubectl -n "${NS}" get hpa "${HPA}" -o jsonpath='{.spec.scaleTargetRef.name}')"
TARGET_API="$(kubectl -n "${NS}" get hpa "${HPA}" -o jsonpath='{.spec.scaleTargetRef.apiVersion}')"

[ "${TARGET_KIND}" = "Deployment" ] || fail "scaleTargetRef.kind must be Deployment (got: ${TARGET_KIND})"
[ "${TARGET_NAME}" = "${DEPLOY}" ] || fail "scaleTargetRef.name must be '${DEPLOY}' (got: ${TARGET_NAME})"
[ "${TARGET_API}" = "apps/v1" ] || fail "scaleTargetRef.apiVersion must be apps/v1 (got: ${TARGET_API})"

MINR="$(kubectl -n "${NS}" get hpa "${HPA}" -o jsonpath='{.spec.minReplicas}')"
MAXR="$(kubectl -n "${NS}" get hpa "${HPA}" -o jsonpath='{.spec.maxReplicas}')"

[ "${MINR}" = "1" ] || fail "minReplicas must be 1 (got: ${MINR})"
[ "${MAXR}" = "4" ] || fail "maxReplicas must be 4 (got: ${MAXR})"

MET_TYPE="$(kubectl -n "${NS}" get hpa "${HPA}" -o jsonpath='{.spec.metrics[0].type}')"
RES_NAME="$(kubectl -n "${NS}" get hpa "${HPA}" -o jsonpath='{.spec.metrics[0].resource.name}')"
TGT_TYPE="$(kubectl -n "${NS}" get hpa "${HPA}" -o jsonpath='{.spec.metrics[0].resource.target.type}')"
AVG_UTIL="$(kubectl -n "${NS}" get hpa "${HPA}" -o jsonpath='{.spec.metrics[0].resource.target.averageUtilization}')"

[ "${MET_TYPE}" = "Resource" ] || fail "metrics[0].type must be Resource (got: ${MET_TYPE})"
[ "${RES_NAME}" = "cpu" ] || fail "metrics[0].resource.name must be cpu (got: ${RES_NAME})"
[ "${TGT_TYPE}" = "Utilization" ] || fail "metrics[0].resource.target.type must be Utilization (got: ${TGT_TYPE})"
[ "${AVG_UTIL}" = "50" ] || fail "metrics target averageUtilization must be 50 (got: ${AVG_UTIL})"

STAB="$(kubectl -n "${NS}" get hpa "${HPA}" -o jsonpath='{.spec.behavior.scaleDown.stabilizationWindowSeconds}')"
[ "${STAB}" = "30" ] || fail "scaleDown stabilizationWindowSeconds must be 30 (got: ${STAB})"

REQ_CPU="$(kubectl -n "${NS}" get deploy "${DEPLOY}" -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}')"
[ -n "${REQ_CPU}" ] || fail "Deployment '${DEPLOY}' must define CPU requests for HPA to work"

echo "==> Best-effort: metrics API check (does not fail the lab)"
set +e
kubectl get --raw /apis/metrics.k8s.io/v1beta1 >/dev/null 2>&1
RC=$?
set -e
if [ "${RC}" -ne 0 ]; then
  echo "WARN: metrics.k8s.io not reachable. HPA might show <unknown> current metrics."
fi

pass "HPA spec matches requirements (target, min/max, CPU 50%, scaleDown window 30s)."
