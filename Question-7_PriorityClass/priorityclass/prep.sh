#!/usr/bin/env bash
# prep.sh — PriorityClass Lab Prep (creates ONLY the starting state)
set -euo pipefail

NS="priority"
DEPLOY="busybox-logger"

echo "==> Creating namespace..."
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"

echo "==> Creating user-defined PriorityClasses (low + medium)..."
kubectl apply -f - <<'EOF'
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: low-priority
value: 500
globalDefault: false
description: "Low priority for user workloads"
---
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: medium-priority
value: 1000
globalDefault: false
description: "Medium priority for user workloads"
EOF

echo "==> Creating Deployment busybox-logger in namespace priority..."
kubectl -n "$NS" apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${DEPLOY}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${DEPLOY}
  template:
    metadata:
      labels:
        app: ${DEPLOY}
    spec:
      containers:
        - name: busybox
          image: busybox:1.36
          command: ["sh","-c","while true; do date; sleep 5; done"]
EOF

echo "==> Waiting for rollout..."
kubectl -n "$NS" rollout status deploy/"$DEPLOY" --timeout=120s

echo
echo "✅ Prep done."
echo "Solve the task:"
echo "1) Create PriorityClass high-priority with value = (highest user-defined - 1), ignoring system-*"
echo "2) Patch Deployment busybox-logger in namespace priority to use priorityClassName: high-priority"
