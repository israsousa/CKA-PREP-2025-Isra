#!/usr/bin/env bash
# check.sh — CRD Question Validator
set -euo pipefail

RES="$HOME/resources.yaml"
SUB="$HOME/subject.yaml"

green() { printf "\e[32m%s\e[0m\n" "$1"; }
red()   { printf "\e[31m%s\e[0m\n" "$1"; }
fail()  { red "FAIL: $*"; exit 1; }
pass()  { green "PASS: $*"; }

echo "=== CHECK: CRDs (cert-manager) ==="

[[ -f "$RES" ]] || fail "Missing file: $RES"
[[ -s "$RES" ]] || fail "File is empty: $RES"

grep -q "certificates.cert-manager.io" "$RES" || fail "$RES does not include certificates.cert-manager.io"
grep -q "issuers.cert-manager.io" "$RES" || fail "$RES does not include issuers.cert-manager.io"

[[ -f "$SUB" ]] || fail "Missing file: $SUB"
[[ -s "$SUB" ]] || fail "File is empty: $SUB"

grep -qi "certificate" "$SUB" || fail "$SUB does not look like kubectl explain output for Certificate"
grep -qi "subject" "$SUB" || fail "$SUB does not contain subject documentation"
grep -qi "organizations" "$SUB" || fail "$SUB missing expected subject subfield (organizations)"

pass "resources.yaml and subject.yaml look correct."
