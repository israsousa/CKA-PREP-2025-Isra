#!/usr/bin/env bash
set -euo pipefail

PKG_NAME="cri-dockerd_0.3.9.3-0.ubuntu-jammy_amd64.deb"
PKG_PATH="/root/${PKG_NAME}"
SYSCTL_FILE="/etc/sysctl.d/k8s.conf"

download_pkg() {
  if [[ -f "$PKG_PATH" ]]; then
    echo "==> Package already exists at: $PKG_PATH"
    return 0
  fi

  echo "==> Package missing. Attempting download to: $PKG_PATH"

  URLS=(
    "https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.9/${PKG_NAME}"
    "https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.9.3/${PKG_NAME}"
    "https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.9.3/${PKG_NAME}"
  )

  if command -v curl >/dev/null 2>&1; then
    for u in "${URLS[@]}"; do
      if curl -fsSL "$u" -o "$PKG_PATH"; then
        echo "==> Downloaded: $u"
        return 0
      fi
    done
  elif command -v wget >/dev/null 2>&1; then
    for u in "${URLS[@]}"; do
      if wget -qO "$PKG_PATH" "$u"; then
        echo "==> Downloaded: $u"
        return 0
      fi
    done
  else
    echo "ERROR: neither curl nor wget is available to download the package."
    exit 1
  fi

  echo "ERROR: Could not download ${PKG_NAME} from GitHub (network blocked or URL mismatch)."
  echo "If your environment blocks internet, you must provide the .deb locally."
  rm -f "$PKG_PATH" >/dev/null 2>&1 || true
  exit 1
}

echo "==> Prepping CRI-Dockerd lab state..."

download_pkg

echo "==> Stopping/disabling cri-docker service if present..."
if systemctl list-unit-files 2>/dev/null | grep -q '^cri-docker\.service'; then
  systemctl disable --now cri-docker >/dev/null 2>&1 || true
fi

echo "==> Removing sysctl persistence file (starting state)..."
rm -f "$SYSCTL_FILE" >/dev/null 2>&1 || true

echo "==> Setting runtime sysctl values to a NON-compliant starting state (best-effort)..."
set +e
sysctl -w net.bridge.bridge-nf-call-iptables=0 >/dev/null 2>&1
sysctl -w net.ipv6.conf.all.forwarding=0 >/dev/null 2>&1
sysctl -w net.ipv4.ip_forward=0 >/dev/null 2>&1
sysctl -w net.netfilter.nf_conntrack_max=65536 >/dev/null 2>&1
set -e

echo
echo "✅ Prep done."
echo "Package ready at: $PKG_PATH"
