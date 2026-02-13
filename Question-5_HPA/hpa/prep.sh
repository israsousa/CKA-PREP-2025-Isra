#!/usr/bin/env bash
set -euo pipefail

echo "=== HPA LAB PREPARATION (CKA/KILLER) ==="

############################################
# 1) Namespace
############################################
echo "🔹 Creating namespace autoscale..."
kubectl create namespace autoscale --dry-run=client -o yaml | kubectl apply -f -

############################################
# 2) Metrics Server
############################################
echo "🔹 Deploying metrics-server..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

echo "🔹 Patching metrics-server for insecure TLS (needed in Killer/VMs)..."
kubectl patch deployment metrics-server -n kube-system \
  --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]' \
  2>/dev/null || true

echo "🔹 Waiting for metrics-server..."
kubectl rollout status deployment metrics-server -n kube-system || true

############################################
# 3) Apache Deployment (CPU requests = OBRIGATÓRIO)
############################################
echo "🔹 Creating Apache deployment..."
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: apache-deployment
  namespace: autoscale
spec:
  replicas: 1
  selector:
    matchLabels:
      app: apache
  template:
    metadata:
      labels:
        app: apache
    spec:
      containers:
      - name: apache
        image: httpd
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 100m
            memory: 64Mi
          limits:
            cpu: 200m
            memory: 128Mi
EOF

echo "🔹 Waiting for deployment..."
kubectl rollout status deployment apache-deployment -n autoscale

############################################
# 4) Service (se não existir)
############################################
echo "🔹 Exposing service..."
kubectl expose deployment apache-deployment -n autoscale \
  --port=80 --target-port=80 \
  --dry-run=client -o yaml | kubectl apply -f -

############################################
# 5) Teste básico metrics API
############################################
echo "🔹 Checking metrics API (best-effort)..."
set +e
kubectl get --raw /apis/metrics.k8s.io/v1beta1 >/dev/null 2>&1
RC=$?
set -e

if [ "${RC}" -ne 0 ]; then
  echo "⚠ metrics API not yet available – normal in first minutes"
fi

echo
echo "✅ HPA LAB READY"
echo "Namespace: autoscale"
echo "Deployment: apache-deployment"
echo
echo "Now solve the exam question by creating HPA 'apache-server'"
