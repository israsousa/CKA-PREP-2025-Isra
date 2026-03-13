#!/bin/bash
set -e

echo "🔹 Creating namespace..."
kubectl create ns mariadb --dry-run=client -o yaml | kubectl apply -f -

echo "🔹 Creating PersistentVolume..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mariadb-pv
  labels:
    app: maria-deployment
spec:
  capacity:
    storage: 250Mi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: standard
  hostPath:
    path: /mnt/data/mariadb
EOF

echo "🔹 Creating initial PVC..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mariadb
  namespace: mariadb
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 250Mi
EOF

echo "🔹 Creating initial MariaDB Deployment..."

cat <<EOF > ~/mariadb-deploy.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: maria-deployment
  namespace: mariadb
  labels:
    app: maria-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: maria-deployment
  template:
    metadata:
      labels:
        app: maria-deployment
    spec:
      containers:
      - name: mariadb
        image: mariadb:10.6
        env:
        - name: MARIADB_ROOT_PASSWORD
          value: mysecretpassword
        volumeMounts:
        - name: mariadb-storage
          mountPath: /var/lib/mysql
      volumes:
      - name: mariadb-storage
        persistentVolumeClaim:
          claimName: mariadb
EOF

kubectl apply -f ~/mariadb-deploy.yaml

echo "🔹 Waiting for MariaDB pod..."
kubectl wait --for=condition=Available deployment/maria-deployment -n mariadb --timeout=60s

echo "🔹 Simulating accidental deletion..."

kubectl delete deployment maria-deployment -n mariadb
kubectl delete pvc mariadb -n mariadb

echo "🔹 Resetting PV for reuse..."

claim_ref=$(kubectl get pv mariadb-pv -o jsonpath='{.spec.claimRef.name}' 2>/dev/null || true)

if [ -n "$claim_ref" ]; then
  kubectl patch pv mariadb-pv --type=json -p '[{"op":"remove","path":"/spec/claimRef"}]'
fi

echo "🔹 Preparing deployment file for the student..."

cat <<'EOF' > ~/mariadb-deploy.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: maria-deployment
  namespace: mariadb
  labels:
    app: maria-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: maria-deployment
  template:
    metadata:
      labels:
        app: maria-deployment
    spec:
      containers:
      - name: mariadb
        image: mariadb:10.6
EOF

echo ""
echo "✅ Lab setup complete!"
echo ""
echo "Tasks:"
echo "1️⃣ Create PVC 'mariadb' in namespace 'mariadb'"
echo "2️⃣ Edit ~/mariadb-deploy.yaml to mount the PVC"
echo "3️⃣ Apply the deployment"
echo ""