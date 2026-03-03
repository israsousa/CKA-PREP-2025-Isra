#!/usr/bin/env bash
set -euo pipefail

PKG_NAME="cri-dockerd_0.3.9.3-0.ubuntu-jammy_amd64.deb"
PKG_PATH="/root/${PKG_NAME}"

green() { printf "\e[32m%s\e[0m\n" "$1"; }
red()   { printf "\e[31m%s\e[0m\n" "$1"; }
fail()  { red "FAIL: $*"; exit 1; }
pass()  { green "PASS: $*"; }

check_persisted() {
  local key="$1"
  local value="$2"

  if ! grep -R --quiet -E "^\s*${key}\s*=\s*${value}\s*$" \
      /etc/sysctl.conf /etc/sysctl.d/*.conf 2>/dev/null; then
    fail "Persisted sysctl ${key}=${value} not found in sysctl configuration files"
  fi
}

echo "=== CHECK: CRI-Dockerd ==="

[[ -f "$PKG_PATH" ]] || fail "Package not found at ${PKG_PATH}"

command -v dpkg >/dev/null 2>&1 || fail "dpkg not found"
dpkg -s cri-dockerd >/dev/null 2>&1 || fail "cri-dockerd not installed"

systemctl is-enabled cri-docker >/dev/null 2>&1 || fail "cri-docker service not enabled"
systemctl is-active cri-docker >/dev/null 2>&1 || fail "cri-docker service not running"

echo "Checking runtime sysctl values..."

[[ "$(sysctl -n net.bridge.bridge-nf-call-iptables 2>/dev/null)" == "1" ]] \
  || fail "Runtime net.bridge.bridge-nf-call-iptables != 1"

[[ "$(sysctl -n net.ipv6.conf.all.forwarding 2>/dev/null)" == "1" ]] \
  || fail "Runtime net.ipv6.conf.all.forwarding != 1"

[[ "$(sysctl -n net.ipv4.ip_forward 2>/dev/null)" == "1" ]] \
  || fail "Runtime net.ipv4.ip_forward != 1"

[[ "$(sysctl -n net.netfilter.nf_conntrack_max 2>/dev/null)" == "131072" ]] \
  || fail "Runtime net.netfilter.nf_conntrack_max != 131072"

echo "Checking sysctl persistence..."

check_persisted net.bridge.bridge-nf-call-iptables 1
check_persisted net.ipv6.conf.all.forwarding 1
check_persisted net.ipv4.ip_forward 1
check_persisted net.netfilter.nf_conntrack_max 131072

pass "cri-dockerd installed, service running/enabled, sysctl applied and persisted correctly."