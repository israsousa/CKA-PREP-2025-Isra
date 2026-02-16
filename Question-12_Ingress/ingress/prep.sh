#!/usr/bin/env bash
# prep.sh — Ingress Resource Lab Prep (creates starting state + installs ingress controller)
set -euo pipefail

NS="echo-sound"
DEPLOY="echo"
SVC="echo-service"
ING="echo"
HOST="example.org"
PATH_PREFIX="/echo"
PORT=8080
NODEPORT=30080

echo "========================================================"
echo "==> Checking for existing Ingress Controller..."
echo "========================================================"

if kubectl get ns ingress-nginx >/dev/null 2>&1; then
  echo "✔ ingress-nginx namespace already exists."
else
  echo "==> Installing NGINX Ingress Controller..."
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.14.3/deploy/static/provider/cloud/deploy.yaml
fi

echo "==> Waiting for ingress controller to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s

echo "✔ Ingress Controller ready."

echo "==> Detecting IngressClass..."
ING_CLASS=$(kubectl get ingressclass -o jsonpath='{.items[0].metadata.name}')

echo "✔ Using IngressClass: ${ING_CLASS}"

echo "========================================================"
echo "==> Creating namespace..."
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"

echo "==> Creating Deployment: $DEPLOY ..."
kubectl -n "$NS" apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${DEPLOY}
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
echo "========================================================"
echo "✅ Prep done."
echo
echo "Your Ingress MUST include:"
echo "  ingressClassName: ${ING_CLASS}"
echo
echo "Solve by creating Ingress '${ING}' in namespace '${NS}'"
echo "Host: ${HOST}"
echo "Path: ${PATH_PREFIX}"
echo "Backend: service ${SVC}:${PORT}"
echo "========================================================"
