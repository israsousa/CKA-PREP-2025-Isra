#!/usr/bin/env bash
# prep.sh — PVC Question Lab Prep
set -euo pipefail

NS="mariadb"
DEPLOY_FILE="$HOME/mariadb-deploy.yaml"

echo "==> Creating namespace..."
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"

echo "==> Creating PersistentVolume (Retain policy)..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mariadb-pv
spec:
  capacity:
    storage: 250Mi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  hostPath:
    path: /mnt/mariadb-data
EOF

echo "==> Creating base MariaDB Deployment manifest (WITHOUT PVC)..."
cat <<EOF > "$DEPLOY_FILE"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mariadb
  namespace: mariadb
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mariadb
  template:
    metadata:
      labels:
        app: mariadb
    spec:
      containers:
        - name: mariadb
          image: mariadb:10.6
          env:
            - name: MYSQL_ROOT_PASSWORD
              value: password
          ports:
            - containerPort: 3306
EOF

echo "==> Applying initial Deployment (no PVC yet)..."
kubectl apply -f "$DEPLOY_FILE"

echo
echo "✅ Prep complete."
echo "You must:"
echo "- Create PVC named 'mariadb' in namespace 'mariadb'"
echo "- Edit ~/mariadb-deploy.yaml to use the PVC"
echo "- Apply the Deployment and verify it is running"
