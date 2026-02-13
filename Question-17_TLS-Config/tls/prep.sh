#!/usr/bin/env bash
set -euo pipefail

NS="nginx-static"
APP="nginx-static"
CM="nginx-config"
TLS_SECRET="nginx-tls"
HOST="codegenitor.k8s.local"

echo "==> Creating namespace..."
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"

echo "==> Creating self-signed TLS secret (if missing)..."
if ! kubectl -n "$NS" get secret "$TLS_SECRET" >/dev/null 2>&1; then
  TMP_DIR="$(mktemp -d)"

  openssl req -x509 -nodes -newkey rsa:2048 \
    -keyout "${TMP_DIR}/tls.key" \
    -out "${TMP_DIR}/tls.crt" \
    -days 365 \
    -subj "/CN=${HOST}"

  kubectl -n "$NS" create secret tls "$TLS_SECRET" \
    --cert="${TMP_DIR}/tls.crt" \
    --key="${TMP_DIR}/tls.key"

  rm -rf "$TMP_DIR"
else
  echo "    Secret $TLS_SECRET already exists — skipping."
fi

echo "==> Creating ConfigMap with TLSv1.2 + TLSv1.3 (starting state)..."
kubectl -n "$NS" apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: ${CM}
data:
  nginx.conf: |
    events {}
    http {
      server {
        listen 443 ssl;
        server_name ${HOST};

        ssl_certificate     /etc/nginx/tls/tls.crt;
        ssl_certificate_key /etc/nginx/tls/tls.key;

        # START STATE: allows TLSv1.2 + TLSv1.3 (you must change to TLSv1.3 only)
        ssl_protocols TLSv1.2 TLSv1.3;

        location / {
          return 200 "OK - NGINX TLS endpoint\n";
        }
      }
    }
EOF

echo "==> Creating Deployment ${APP}..."
kubectl -n "$NS" apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${APP}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${APP}
  template:
    metadata:
      labels:
        app: ${APP}
    spec:
      containers:
        - name: nginx
          image: nginx:stable
          ports:
            - name: https
              containerPort: 443
          volumeMounts:
            - name: nginx-config
              mountPath: /etc/nginx/nginx.conf
              subPath: nginx.conf
            - name: tls
              mountPath: /etc/nginx/tls
              readOnly: true
      volumes:
        - name: nginx-config
          configMap:
            name: ${CM}
        - name: tls
          secret:
            secretName: ${TLS_SECRET}
EOF

echo "==> Creating Service ${APP} (ClusterIP)..."
kubectl -n "$NS" apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: ${APP}
spec:
  selector:
    app: ${APP}
  ports:
    - name: https
      port: 443
      targetPort: 443
EOF

echo "==> Waiting for deployment rollout..."
kubectl -n "$NS" rollout status deploy/"$APP"

echo
echo "✅ Prep done."
