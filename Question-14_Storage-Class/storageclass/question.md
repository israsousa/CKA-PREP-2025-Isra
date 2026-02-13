## `question.md`

```md
# Question – StorageClass

You are working in a Kubernetes cluster where dynamic volume provisioning is enabled.

## Tasks

1. Create a **StorageClass** named **local-codegenitor**.
2. The StorageClass must use the provisioner:
```

rancher.io/local-path

````

3. Configure the StorageClass so that:
- The `volumeBindingMode` is set to **WaitForFirstConsumer**
4. Configure the StorageClass to be the **default StorageClass** in the cluster.

## Constraints

- Do **not** modify any existing:
- Deployments
- PersistentVolumeClaims
- PersistentVolumes
- Only create or modify the StorageClass as required.

---

## Solution

### Step 1: Create the StorageClass manifest

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
name: local-codegenitor
annotations:
 storageclass.kubernetes.io/is-default-class: "true"
provisioner: rancher.io/local-path
volumeBindingMode: WaitForFirstConsumer
````

Apply it:

```bash
kubectl apply -f storageclass.yaml
```

---

### Step 2: Verify the StorageClass

```bash
kubectl get storageclass
```

Expected output includes:

```
NAME               PROVISIONER               DEFAULT
local-codegenitor  rancher.io/local-path    yes
```

---

## 🧠 Exam Memory Anchors

- **StorageClass is cluster-scoped** (no namespace)
- `WaitForFirstConsumer` = volume created **only after Pod scheduling**
- Default StorageClass requires **annotation**, not a spec field
- Only **one** default StorageClass should exist

---

## Common Exam Traps (Avoid These)

❌ Forgetting the default annotation
❌ Using `Immediate` instead of `WaitForFirstConsumer`
❌ Modifying existing PVCs (explicitly forbidden)
❌ Adding a namespace to StorageClass (invalid)

---

## One-Line Exam Summary

> “Create a default StorageClass with local-path provisioner and delayed binding.”

```

```
