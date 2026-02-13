#!/usr/bin/env bash
# check.sh — StorageClass (Default) Validator (PASS/FAIL)
set -euo pipefail

SC_NEW="local-codegenitor"
SC_OLD="local-path"
REQ_PROVISIONER="rancher.io/local-path"
REQ_BINDING="WaitForFirstConsumer"

green() { printf "\e[32m%s\e[0m\n" "$1"; }
red()   { printf "\e[31m%s\e[0m\n" "$1"; }
fail()  { red "FAIL: $*"; exit 1; }
pass()  { green "PASS: $*"; }

echo "=== CHECK: StorageClass ==="

kubectl get sc "${SC_NEW}" >/dev/null 2>&1 || fail "StorageClass '${SC_NEW}' not found"
kubectl get sc "${SC_OLD}" >/dev/null 2>&1 || fail "Expected existing StorageClass '${SC_OLD}' not found"

# --- Validate NEW StorageClass fields ---
prov="$(kubectl get sc "${SC_NEW}" -o jsonpath='{.provisioner}')"
[[ "$prov" == "$REQ_PROVISIONER" ]] || fail "'${SC_NEW}' provisioner is '$prov' (expected '${REQ_PROVISIONER}')"

binding="$(kubectl get sc "${SC_NEW}" -o jsonpath='{.volumeBindingMode}')"
[[ "$binding" == "$REQ_BINDING" ]] || fail "'${SC_NEW}' volumeBindingMode is '$binding' (expected '${REQ_BINDING}')"

# --- Default annotation checks (robust jsonpath for dotted key) ---
new_default="$(kubectl get sc "${SC_NEW}" -o jsonpath='{.metadata.annotations["storageclass.kubernetes.io/is-default-class"]}')"
[[ "$new_default" == "true" ]] || fail "StorageClass '${SC_NEW}' is not marked as default (annotation storageclass.kubernetes.io/is-default-class=true missing)"

old_default="$(kubectl get sc "${SC_OLD}" -o jsonpath='{.metadata.annotations["storageclass.kubernetes.io/is-default-class"]}' 2>/dev/null || true)"
[[ "$old_default" != "true" ]] || fail "StorageClass '${SC_OLD}' is still default. Remove default annotation from it."

# --- Ensure ONLY ONE default exists ---
defaults="$(kubectl get sc -o jsonpath='{range .items[*]}{.metadata.name}{"="}{.metadata.annotations["storageclass.kubernetes.io/is-default-class"]}{"\n"}{end}' \
  | awk -F= '$2=="true"{print $1}')"

count="$(echo "$defaults" | awk 'NF{c++} END{print c+0}')"
[[ "$count" -eq 1 ]] || fail "More than one default StorageClass exists: $(echo "$defaults" | tr '\n' ' ')"
[[ "$(echo "$defaults" | head -n1)" == "$SC_NEW" ]] || fail "Default StorageClass is not '${SC_NEW}'"

pass "StorageClass '${SC_NEW}' exists, uses '${REQ_PROVISIONER}', volumeBindingMode '${REQ_BINDING}', and is the ONLY default."
