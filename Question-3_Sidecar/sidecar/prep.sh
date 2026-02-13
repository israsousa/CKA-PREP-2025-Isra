#!/usr/bin/env bash
# prep.sh — Sidecar Container Lab (CKA style)
set -euo pipefail

NS="${NS:-default}"
DEPLOY="${DEPLOY:-wordpress}"

echo "==> Using namespace: ${NS}"
kubectl get ns "${NS}" >/dev/null 2>&1 || kubectl create ns "${NS}"

echo "==> Cleaning old deployment (if any)"
kubectl -n "${NS}" delete deploy "${DEPLOY}" --ignore-not-found >/dev/null 2>&1 || true

echo "==> Creating base wordpress Deployment (single container) that writes /var/log/wordpress.log"
cat <<'YAML' | kubectl -n "${NS}" apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress
spec:
  replicas: 1
  selector:
    matchLabels:
      app: wordpress
  template:
    metadata:
      labels:
        app: wordpress
    spec:
      containers:
        - name: wordpress
          image: busybox:stable
          command:
            - /bin/sh
            - -c
            - |
              mkdir -p /var/log;
              i=1;
              while true; do
                echo "$(date) wordpress log line $i" >> /var/log/wordpress.log;
                i=$((i+1));
                sleep 2;
              done
YAML

echo "==> Waiting for rollout..."
kubectl -n "${NS}" rollout status deploy/"${DEPLOY}" --timeout=120s

echo
echo "✅ Prep complete."
echo "Task:"
echo " - Update deployment '${DEPLOY}'"
echo " - Add shared volume mounted at /var/log"
echo " - Add sidecar container name=sidecar image=busybox:stable"
echo " - Sidecar command: /bin/sh -c \"tail -f /var/log/wordpress.log\""
echo " - Do NOT use initContainers"
