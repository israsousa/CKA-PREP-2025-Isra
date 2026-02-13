#!/usr/bin/env bash
# prep.sh — NetworkPolicy Lab Prep (creates ONLY the starting state)
set -euo pipefail

FRONT_NS="frontend"
BACK_NS="backend"

FRONT_DEPLOY="frontend"
BACK_DEPLOY="backend"
BACK_SVC="backend-svc"

echo "==> Creating namespaces..."
kubectl get ns "$FRONT_NS" >/dev/null 2>&1 || kubectl create ns "$FRONT_NS"
kubectl get ns "$BACK_NS"  >/dev/null 2>&1 || kubectl create ns "$BACK_NS"

echo "==> Creating backend Deployment (listens on TCP 8080) ..."
kubectl -n "$BACK_NS" apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${BACK_DEPLOY}
  namespace: ${BACK_NS}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
        - name: backend
          image: hashicorp/http-echo:0.2.3
          args: ["-listen=:8080", "-text=backend ok"]
          ports:
            - containerPort: 8080
EOF

echo "==> Creating backend Service (ClusterIP :8080 -> 8080) ..."
kubectl -n "$BACK_NS" apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: ${BACK_SVC}
  namespace: ${BACK_NS}
spec:
  selector:
    app: backend
  ports:
    - name: http
      port: 8080
      targetPort: 8080
EOF

echo "==> Creating frontend Deployment (curl tools pod) ..."
kubectl -n "$FRONT_NS" apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${FRONT_DEPLOY}
  namespace: ${FRONT_NS}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
        - name: frontend
          image: curlimages/curl:8.5.0
          command: ["/bin/sh","-c","sleep 360000"]
EOF

echo "==> Waiting for rollouts..."
kubectl -n "$BACK_NS"  rollout status deploy/"$BACK_DEPLOY"
kubectl -n "$FRONT_NS" rollout status deploy/"$FRONT_DEPLOY"

echo
echo "✅ Prep complete."
echo "Starting state:"
echo "- Namespaces: frontend, backend"
echo "- Deployment frontend (label app=frontend) in namespace frontend"
echo "- Deployment backend (label app=backend) in namespace backend"
echo "- Service backend-svc on TCP 8080 in namespace backend"
echo
echo "Next: create the NetworkPolicy in backend namespace (least privilege)."
