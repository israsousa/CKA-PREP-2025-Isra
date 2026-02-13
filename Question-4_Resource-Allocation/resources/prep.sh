#!/usr/bin/env bash
# prep.sh — Resource Requests/Limits lab prep (codegenitor)
set -euo pipefail

NS="default"
DEPLOY="wordpress"

echo "==> Prepping Resource Requests/Limits lab state..."

# Clean old deployment if it exists
if kubectl get deploy "$DEPLOY" -n "$NS" >/dev/null 2>&1; then
  echo "==> Removing existing deployment $DEPLOY (if any)..."
  kubectl delete deploy "$DEPLOY" -n "$NS" --ignore-not-found
fi

echo "==> Creating Deployment '$DEPLOY' in namespace '$NS' with 3 replicas"
echo "    - Includes 1 initContainer + 1 main container"
echo "    - No resources set initially"

kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${DEPLOY}
  namespace: ${NS}
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ${DEPLOY}
  template:
    metadata:
      labels:
        app: ${DEPLOY}
    spec:
      initContainers:
        - name: init-setup
          image: busybox:1.36
          command: ["sh", "-c", "echo init running; sleep 2"]
      containers:
        - name: wordpress
          image: nginx:1.27
          ports:
            - containerPort: 80
EOF

echo
echo "✅ Prep complete."
echo "You must:"
echo "1) Scale deployment '${DEPLOY}' down to 0"
echo "2) Add CPU+memory requests/limits to BOTH initContainer and main container"
echo "   - They must be EXACTLY the same values"
echo "3) Scale deployment '${DEPLOY}' back to 3"
echo
echo "Hint: use 'kubectl edit deployment ${DEPLOY}'"
