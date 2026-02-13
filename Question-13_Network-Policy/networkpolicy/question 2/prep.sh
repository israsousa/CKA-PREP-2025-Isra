#!/usr/bin/env bash
# prep.sh — CKA NetPol Lab: Frontend <-> Backend (least privilege)
set -euo pipefail

NETPOLDIR="${HOME}/netpol"

echo "==> Creating namespaces: frontend, backend, other"
kubectl get ns frontend >/dev/null 2>&1 || kubectl create ns frontend
kubectl get ns backend  >/dev/null 2>&1 || kubectl create ns backend
kubectl get ns other    >/dev/null 2>&1 || kubectl create ns other

echo "==> Label namespaces for namespaceSelector matching"
kubectl label ns frontend kubernetes.io/metadata.name=frontend --overwrite
kubectl label ns backend  kubernetes.io/metadata.name=backend  --overwrite
kubectl label ns other    kubernetes.io/metadata.name=other    --overwrite

echo "==> Deploying backend app (http-echo) + Service on port 8080"
cat <<'YAML' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: backend
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
          image: hashicorp/http-echo:1.0
          args: ["-text=backend-ok", "-listen=:8080"]
          ports:
            - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: backend
  namespace: backend
spec:
  selector:
    app: backend
  ports:
    - name: http
      port: 8080
      targetPort: 8080
YAML

echo "==> Deploying frontend client (curl) + ServiceAccount"
cat <<'YAML' | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: frontend-sa
  namespace: frontend
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: frontend
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
      serviceAccountName: frontend-sa
      containers:
        - name: frontend
          image: curlimages/curl:8.5.0
          command: ["/bin/sh","-c"]
          args:
            - |
              echo "frontend ready";
              sleep 360000
YAML

echo "==> Deploying 'other' client (curl) for negative testing"
cat <<'YAML' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: other-client
  namespace: other
spec:
  replicas: 1
  selector:
    matchLabels:
      app: other-client
  template:
    metadata:
      labels:
        app: other-client
    spec:
      containers:
        - name: other-client
          image: curlimages/curl:8.5.0
          command: ["/bin/sh","-c"]
          args:
            - |
              echo "other-client ready";
              sleep 360000
YAML

echo "==> Waiting for pods to become Ready..."
kubectl -n backend  rollout status deploy/backend  --timeout=180s
kubectl -n frontend rollout status deploy/frontend --timeout=180s
kubectl -n other    rollout status deploy/other-client --timeout=180s

echo "==> Applying deny-all NetworkPolicies (DO NOT MODIFY/DELETE during the task)"
cat <<'YAML' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
  namespace: backend
spec:
  podSelector: {}
  policyTypes:
    - Ingress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-egress
  namespace: backend
spec:
  podSelector: {}
  policyTypes:
    - Egress
  egress: []
YAML

echo "==> Creating candidate NetworkPolicy YAML files in ${NETPOLDIR}"
mkdir -p "${NETPOLDIR}"

# Candidate 1: TOO PERMISSIVE (allows any namespace)
cat <<'YAML' > "${NETPOLDIR}/01-allow-any-namespace.yaml"
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-backend-from-any-namespace
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes: ["Ingress"]
  ingress:
    - from:
        - namespaceSelector: {}
      ports:
        - protocol: TCP
          port: 8080
YAML

# Candidate 2: WRONG PORT (9090)
cat <<'YAML' > "${NETPOLDIR}/02-allow-frontend-wrong-port.yaml"
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-wrong-port
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes: ["Ingress"]
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: frontend
          podSelector:
            matchLabels:
              app: frontend
      ports:
        - protocol: TCP
          port: 9090
YAML

# Candidate 3: CORRECT (least privilege) ✅
cat <<'YAML' > "${NETPOLDIR}/03-allow-frontend-to-backend.yaml"
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes: ["Ingress"]
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: frontend
          podSelector:
            matchLabels:
              app: frontend
      ports:
        - protocol: TCP
          port: 8080
YAML

# Candidate 4: WRONG (allows backend pods but selects all pods)
cat <<'YAML' > "${NETPOLDIR}/04-allow-from-frontend-all-pods.yaml"
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-frontend-all-pods
  namespace: backend
spec:
  podSelector: {}
  policyTypes: ["Ingress"]
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: frontend
      ports:
        - protocol: TCP
          port: 8080
YAML

echo
echo "✅ Prep complete."
echo "Task:"
echo "  - Inspect deployments/ports/labels"
echo "  - In ${NETPOLDIR}, choose ONE NetworkPolicy YAML to apply"
echo "  - Must allow ONLY frontend -> backend on TCP 8080 (least privilege)"
echo "  - DO NOT delete/modify deny-all policies"
