#!/usr/bin/env bash
# prep.sh — Gateway API Migration Lab Prep (Codegenitor)
# - Installs Gateway API CRDs if missing
# - Installs an NGINX Gateway controller (NGINX Gateway Fabric)
# - Creates an existing Ingress app you will migrate to Gateway + HTTPRoute
set -euo pipefail

HOSTNAME="gateway.web.k8s.local"
GWCLASS="nginx-class"
TLS_SECRET="web-tls"
SVC_NAME="web-service"
DEPLOY_NAME="web-app"
ING_NAME="web"

echo "==> Checking for Gateway API CRDs..."
if ! kubectl api-resources | grep -qE '^gateways[[:space:]]'; then
  echo "==> Gateway API not found. Installing Gateway API CRDs..."
  # Standard Gateway API CRDs
  kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.0/standard-install.yaml

  echo "==> Installing NGINX Gateway Fabric controller (includes GatewayClass)..."
  # NGINX Gateway Fabric (a popular Gateway API controller)
  kubectl apply -f https://raw.githubusercontent.com/nginxinc/nginx-gateway-fabric/v1.4.0/deploy/crds.yaml
  kubectl apply -f https://raw.githubusercontent.com/nginxinc/nginx-gateway-fabric/v1.4.0/deploy/default/deploy.yaml

  echo "==> Waiting for controller to become ready..."
  kubectl -n nginx-gateway get deploy >/dev/null 2>&1 || true
  kubectl -n nginx-gateway rollout status deploy/nginx-gateway -w --timeout=180s || true

  echo "==> Re-checking Gateway API CRDs..."
  kubectl api-resources | grep -qE '^gateways[[:space:]]' || {
    echo "ERROR: Gateway API CRDs still not available after install."
    echo "Try: kubectl api-resources | grep -i gateway"
    exit 1
  }
fi

echo "==> Ensuring GatewayClass '${GWCLASS}' exists..."
# Many controllers create their own GatewayClass. We ensure the one we check for exists.
kubectl get gatewayclass "${GWCLASS}" >/dev/null 2>&1 || kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: ${GWCLASS}
spec:
  controllerName: gateway.nginx.org/nginx-gateway-controller
EOF

echo "==> Creating demo app Deployment + Service..."
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${DEPLOY_NAME}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${DEPLOY_NAME}
  template:
    metadata:
      labels:
        app: ${DEPLOY_NAME}
    spec:
      containers:
        - name: app
          image: nginx:1.25
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: ${SVC_NAME}
spec:
  selector:
    app: ${DEPLOY_NAME}
  ports:
    - name: http
      port: 80
      targetPort: 80
EOF

echo "==> Creating TLS secret '${TLS_SECRET}' (self-signed)..."
TMPDIR="$(mktemp -d)"
openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout "${TMPDIR}/tls.key" \
  -out "${TMPDIR}/tls.crt" \
  -subj "/CN=${HOSTNAME}" >/dev/null 2>&1

kubectl delete secret "${TLS_SECRET}" >/dev/null 2>&1 || true
kubectl create secret tls "${TLS_SECRET}" \
  --cert="${TMPDIR}/tls.crt" \
  --key="${TMPDIR}/tls.key" >/dev/null

rm -rf "${TMPDIR}"

echo "==> Creating the existing Ingress '${ING_NAME}' (source state)..."
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ${ING_NAME}
spec:
  tls:
    - hosts:
        - ${HOSTNAME}
      secretName: ${TLS_SECRET}
  rules:
    - host: ${HOSTNAME}
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: ${SVC_NAME}
                port:
                  number: 80
EOF

echo
echo "✅ Prep complete."
echo "Existing Ingress:"
echo "  - name: ${ING_NAME}"
echo "  - host: ${HOSTNAME}"
echo "  - tls secret: ${TLS_SECRET}"
echo "  - backend svc: ${SVC_NAME}:80"
echo
echo "Your task:"
echo "  1) Create Gateway:   web-gateway (GatewayClass: ${GWCLASS}, HTTPS 443, hostname ${HOSTNAME}, TLS secret ${TLS_SECRET})"
echo "  2) Create HTTPRoute: web-route   (attach to web-gateway, hostname ${HOSTNAME}, PathPrefix / -> ${SVC_NAME}:80)"
