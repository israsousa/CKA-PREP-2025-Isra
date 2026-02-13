#!/usr/bin/env bash
set -euo pipefail

PKG_NAME="cri-dockerd_0.3.9.3-0.ubuntu-jammy_amd64.deb"
PKG_PATH="/root/${PKG_NAME}"
SYSCTL_FILE="/etc/sysctl.d/k8s.conf"

green() { printf "\e[32m%s\e[0m\n" "$1"; }
red()   { printf "\e[31m%s\e[0m\n" "$1"; }
fail()  { red "FAIL: $*"; exit 1; }
pass()  { green "PASS: $*"; }

echo "=== CHECK: CRI-Dockerd ==="

[[ -f "$PKG_PATH" ]] || fail "Package not found at ${PKG_PATH}"

command -v dpkg >/dev/null 2>&1 || fail "dpkg not found"
dpkg -s cri-dockerd >/dev/null 2>&1 || fail "cri-dockerd not installed (dpkg -s cri-dockerd failed)"

systemctl is-enabled cri-docker >/dev/null 2>&1 || fail "cri-docker service is not enabled"
systemctl is-active cri-docker >/dev/null 2>&1 || fail "cri-docker service is not running"

[[ -f "$SYSCTL_FILE" ]] || fail "Missing sysctl persistence file: ${SYSCTL_FILE}"

grep -qE '^\s*net\.bridge\.bridge-nf-call-iptables\s*=\s*1\s*$' "$SYSCTL_FILE" || fail "k8s.conf missing net.bridge.bridge-nf-call-iptables=1"
grep -qE '^\s*net\.ipv6\.conf\.all\.forwarding\s*=\s*1\s*$' "$SYSCTL_FILE" || fail "k8s.conf missing net.ipv6.conf.all.forwarding=1"
grep -qE '^\s*net\.ipv4\.ip_forward\s*=\s*1\s*$' "$SYSCTL_FILE" || fail "k8s.conf missing net.ipv4.ip_forward=1"
grep -qE '^\s*net\.netfilter\.nf_conntrack_max\s*=\s*131072\s*$' "$SYSCTL_FILE" || fail "k8s.conf missing net.netfilter.nf_conntrack_max=131072"

v1="$(sysctl -n net.bridge.bridge-nf-call-iptables 2>/dev/null || echo "")"
v2="$(sysctl -n net.ipv6.conf.all.forwarding 2>/dev/null || echo "")"
v3="$(sysctl -n net.ipv4.ip_forward 2>/dev/null || echo "")"
v4="$(sysctl -n net.netfilter.nf_conntrack_max 2>/dev/null || echo "")"

[[ "$v1" == "1" ]] || fail "Runtime sysctl net.bridge.bridge-nf-call-iptables is $v1 (expected 1)"
[[ "$v2" == "1" ]] || fail "Runtime sysctl net.ipv6.conf.all.forwarding is $v2 (expected 1)"
[[ "$v3" == "1" ]] || fail "Runtime sysctl net.ipv4.ip_forward is $v3 (expected 1)"
[[ "$v4" == "131072" ]] || fail "Runtime sysctl net.netfilter.nf_conntrack_max is $v4 (expected 131072)"

pass "cri-dockerd installed, cri-docker running/enabled, sysctl persisted + applied."
