## `question.md` (CKA-grade, explicit, exam-style)

````md
# Question – NetworkPolicy (Least Privilege)

Two applications are running in the Kubernetes cluster.

### Existing Resources

1. A Deployment named **frontend** is running in the **frontend** namespace.

   - Pods have the label:  
     `app=frontend`

2. A Deployment named **backend** is running in the **backend** namespace.

   - Pods have the label:  
     `app=backend`
   - The backend Pods listen on **TCP port 8080**.

3. No NetworkPolicies currently exist in either namespace.

---

## Tasks

1. Create a NetworkPolicy named **frontend-to-backend** in the **backend** namespace.
2. The NetworkPolicy must allow **ingress traffic only** from:
   - Pods with label `app=frontend`
   - From the **frontend** namespace
3. Allow traffic **only on TCP port 8080**.
4. All other ingress traffic to backend Pods must be denied.
5. Do **not** modify any existing Deployments or Services.

---

## Notes

- The NetworkPolicy must be **least permissive**.

---

## ✅ Solution (Exam-correct)

### Step 1: Verify labels (always do this in exam)

```bash
kubectl get pods -n frontend --show-labels
kubectl get pods -n backend --show-labels
```
````

Confirm:

- frontend Pods → `app=frontend`
- backend Pods → `app=backend`

---

### Step 2: Create the NetworkPolicy

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-to-backend
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
    - Ingress
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
```

Apply it:

```bash
kubectl apply -f networkpolicy.yaml
```

---

### Step 3: Verify

```bash
kubectl get networkpolicy -n backend
kubectl describe networkpolicy frontend-to-backend -n backend
```

Expected result:

- Frontend Pods → ✅ can reach backend on TCP 8080
- Any other Pod → ❌ blocked
- Any other port → ❌ blocked

---

## 🧠 Why this matches the real exam

✔ Explicit namespaces
✔ Explicit labels
✔ Explicit port
✔ Explicit policy scope
✔ Least-privilege enforced
✔ No assumptions
✔ Deterministic grading

This is **exactly** how CKA graders evaluate NetworkPolicy tasks.
