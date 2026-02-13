```md
# CKA Practice Question – PersistentVolumeClaim (PVC)

## Question – Persistent Volume Claim

A **PersistentVolume** already exists in the cluster and is retained for reuse.

Create a **PersistentVolumeClaim** named `mariadb` in the `mariadb` namespace with the following requirements:

1. Access mode must be `ReadWriteOnce`
2. Requested storage size must be `250Mi`

A MariaDB Deployment manifest is available at:
```

~/mariadb-deploy.yaml

````

### Tasks

1. Create the required PersistentVolumeClaim.
2. Edit the Deployment manifest so that it uses the newly created PVC.
3. Apply the Deployment.
4. Verify that the Deployment is running and stable.

---

## ✅ Solution

### Step 1 – Create the PersistentVolumeClaim

```bash
kubectl apply -n mariadb -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mariadb
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 250Mi
EOF
````

---

### Step 2 – Edit the Deployment Manifest

Open the deployment file:

```bash
vi ~/mariadb-deploy.yaml
```

Add the volume definition under `spec.template.spec`:

```yaml
volumes:
  - name: mariadb-data
    persistentVolumeClaim:
      claimName: mariadb
```

Mount the volume inside the MariaDB container:

```yaml
volumeMounts:
  - name: mariadb-data
    mountPath: /var/lib/mysql
```

---

### Step 3 – Apply the Deployment

```bash
kubectl apply -f ~/mariadb-deploy.yaml
```

---

### Step 4 – Verify Deployment Status

```bash
kubectl rollout status deployment/mariadb -n mariadb
kubectl get pods -n mariadb
```

The Deployment should be running with Pods in the `Running` state.

---

## Notes (Exam Tip)

- You are **not creating a new PersistentVolume**, only a **PVC**.
- Kubernetes will automatically bind the PVC to the existing PV.
- Always verify the mount path matches the application’s expected data directory.

This task tests **PVC usage, Deployment editing, and data persistence**, which commonly appears in the CKA exam.

```

```
