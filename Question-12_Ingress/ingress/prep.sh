#!/usr/bin/env bash
# prep.sh — Ingress Resource Lab Prep (creates ONLY the starting state)
set -euo pipefail

NS="echo-sound"
DEPLOY="echo"
SVC="echo-service"
ING="echo"
HOST="example.org"
PATH_PREFIX="/echo"
PORT=8080
NODEPORT=30080

echo "==> Creating namespace..."
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"

echo "==> Creating Deployment: $DEPLOY ..."
kubectl -n "$NS" apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${DEPLOY}
  namespace: ${NS}
spec:
  replicas: 2
  selector:
    matchLabels:
      app: ${DEPLOY}
  template:
    metadata:
      labels:
        app: ${DEPLOY}
    spec:
      containers:
        - name: http-echo
          image: hashicorp/http-echo:1.0
          args:
            - "-text=OK - echo endpoint"
          ports:
            - containerPort: ${PORT}
EOF

echo "==> Creating Service: $SVC (NodePort ${NODEPORT}) ..."
kubectl -n "$NS" apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: ${SVC}
  namespace: ${NS}
spec:
  type: NodePort
  selector:
    app: ${DEPLOY}
  ports:
    - name: http
      port: ${PORT}
      targetPort: ${PORT}
      nodePort: ${NODEPORT}
EOF

echo "==> Removing Ingress if it exists (so lab starts unsolved)..."
kubectl -n "$NS" delete ingress "$ING" --ignore-not-found=true >/dev/null 2>&1 || true

echo "==> Waiting for deployment rollout..."
kubectl -n "$NS" rollout status deploy/"$DEPLOY"

echo
echo "✅ Prep done."
echo "Solve by creating Ingress '${ING}' in namespace '${NS}'"
echo "Host: ${HOST}"
echo "Path: ${PATH_PREFIX}"
echo "Backend: service ${SVC}:${PORT}"
