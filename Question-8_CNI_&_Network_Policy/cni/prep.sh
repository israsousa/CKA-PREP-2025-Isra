#!/usr/bin/env bash
set -euo pipefail

NS="codegenitor-cni"
APP="echo"
SVC="echo-svc"

echo "==> Creating namespace: $NS"
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"

echo "==> Creating echo server (nginx) + service"
kubectl -n "$NS" apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: echo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: echo
  template:
    metadata:
      labels:
        app: echo
    spec:
      containers:
        - name: nginx
          image: nginx:stable
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: echo-svc
spec:
  selector:
    app: echo
  ports:
    - name: http
      port: 80
      targetPort: 80
EOF

echo "==> Creating client pods (allowed + denied)"
kubectl -n "$NS" apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: client-allowed
  labels:
    client: "true"
    access: "granted"
spec:
  containers:
    - name: bb
      image: busybox:stable
      command: ["sh","-c","sleep 365d"]
---
apiVersion: v1
kind: Pod
metadata:
  name: client-denied
  labels:
    client: "true"
    access: "blocked"
spec:
  containers:
    - name: bb
      image: busybox:stable
      command: ["sh","-c","sleep 365d"]
EOF

echo "==> Waiting for readiness"
kubectl -n "$NS" rollout status deploy/"$APP" --timeout=120s
kubectl -n "$NS" wait --for=condition=Ready pod/client-allowed --timeout=120s
kubectl -n "$NS" wait --for=condition=Ready pod/client-denied --timeout=120s

echo
echo "✅ Prep done."
echo "Solve the CNI question, then run: ./check.sh"
