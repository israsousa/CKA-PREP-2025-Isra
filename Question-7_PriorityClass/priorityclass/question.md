## `question.md`

```md
# Question – PriorityClass

You are working in a Kubernetes cluster that already contains:

- A namespace named **priority**
- A Deployment named **busybox-logger** running in the **priority** namespace
- At least **one user-defined PriorityClass** already exists in the cluster

## Tasks

1. Create a new **PriorityClass** named **high-priority** for user workloads.
2. The **value** of this PriorityClass must be:
   - **Exactly one less** than the **highest existing user-defined PriorityClass value** in the cluster.
3. Patch the existing Deployment **busybox-logger** in the **priority** namespace so that:
   - All Pods use the newly created **high-priority** PriorityClass.

Do **not** modify any other fields of the Deployment unless required.

---

## Notes

- System PriorityClasses (e.g. `system-node-critical`) must be ignored.
- You may use any valid `kubectl` commands to inspect existing PriorityClasses.
```

---

# ✅ Solution

## Step 1: Inspect existing PriorityClasses

```bash
kubectl get priorityclass
```

Example output:

```
NAME               VALUE
medium-priority    1000
low-priority       500
```

👉 Highest **user-defined** value here is `1000`.

---

## Step 2: Create the new PriorityClass

Required value:

```
1000 - 1 = 999
```

Create the PriorityClass:

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 999
globalDefault: false
description: "High priority for critical user workloads"
```

Apply it:

```bash
kubectl apply -f - <<EOF
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 999
globalDefault: false
description: "High priority for critical user workloads"
EOF
```

---

## Step 3: Patch the Deployment to use the PriorityClass

```bash
kubectl patch deployment busybox-logger -n priority \
  --type='json' \
  -p='[
    {
      "op": "add",
      "path": "/spec/template/spec/priorityClassName",
      "value": "high-priority"
    }
  ]'
```

---

## Step 4: Verify

```bash
kubectl get pods -n priority -o=jsonpath='{.items[*].spec.priorityClassName}'
```

Expected output:

```
high-priority
```

---

## 🧠 Exam Memory Trick (Never Forget This)

**PriorityClass logic = ranking numbers**

- Bigger number = more important Pod
- Scheduler evicts **lower numbers first**
- Exam trick:

  > “One less than highest” → **inspect first, then subtract**
