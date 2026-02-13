#!/usr/bin/env bash
# prep.sh — StorageClass (Default) Lab Prep (starting state only)
set -euo pipefail

SC_NEW="local-codegenitor"
SC_EXISTING="local-path"

echo "==> Prepping StorageClass lab state..."

echo "==> Cleaning old lab StorageClass if it exists..."
kubectl get sc "${SC_NEW}" >/dev/null 2>&1 && kubectl delete sc "${SC_NEW}"

echo "==> Ensuring existing StorageClass '${SC_EXISTING}' exists..."
kubectl get sc "${SC_EXISTING}" >/dev/null 2>&1 || {
  echo "ERROR: Expected StorageClass '${SC_EXISTING}' to exist in this cluster."
  exit 1
}

echo "==> Setting '${SC_EXISTING}' as the ONLY default (starting state)..."
# Mark existing as default
kubectl annotate sc "${SC_EXISTING}" storageclass.kubernetes.io/is-default-class="true" --overwrite >/dev/null

# Ensure no other StorageClass is default (avoid surprise)
for sc in $(kubectl get sc -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'); do
  [[ "$sc" == "${SC_EXISTING}" ]] && continue
  ann="$(kubectl get sc "$sc" -o jsonpath='{.metadata.annotations["storageclass.kubernetes.io/is-default-class"]}' 2>/dev/null || true)"
  if [[ "$ann" == "true" ]]; then
    kubectl annotate sc "$sc" storageclass.kubernetes.io/is-default-class- --overwrite >/dev/null || true
  fi
done

echo
echo "✅ Prep complete."
echo "Starting state:"
echo "- StorageClass '${SC_EXISTING}' is DEFAULT"
echo "- StorageClass '${SC_NEW}' does NOT exist"
echo
echo "Your task:"
echo "1) Create StorageClass '${SC_NEW}' with provisioner 'rancher.io/local-path'"
echo "2) Set volumeBindingMode to 'WaitForFirstConsumer'"
echo "3) Make '${SC_NEW}' the DEFAULT StorageClass (and '${SC_EXISTING}' must NOT be default)"
