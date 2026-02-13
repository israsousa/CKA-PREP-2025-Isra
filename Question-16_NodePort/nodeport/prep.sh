#!/usr/bin/env bash
# prep.sh — NodePort Question Lab Prep (creates ONLY the starting state)
set -euo pipefail

NS="default"
DEP="nodeport-deployment"
SVC="nodeport-service"

echo "==> Preparing start state for NodePort question in namespace: ${NS}"

echo "==> Ensuring Deployment ${DEP} exists (START STATE: no containerPort set)..."
kubectl -n "${NS}" apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nodeport-deployment
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nodeport-deployment
  template:
    metadata:
      labels:
        app: nodeport-deployment
    spec:
      containers:
        - name: web
          image: nginx:stable
          # START STATE: ports intentionally missing (candidate must add containerPort 80/TCP)
EOF

echo "==> Deleting Service ${SVC} if it exists (START STATE: Service should be missing)..."
kubectl -n "${NS}" delete svc "${SVC}" --ignore-not-found

echo "==> Waiting for Deployment rollout..."
kubectl -n "${NS}" rollout status deploy/"${DEP}"

echo
echo "✅ Prep done."
echo "Next: Solve the question by updating the Deployment ports and creating the NodePort Service."
