# Question – Pod Resource Requests and Limits

You are managing a **WordPress** application running in a Kubernetes cluster.

### Existing State

- A Deployment named **wordpress** exists in the **default** namespace.
- The Deployment currently runs **3 replicas**.
- Each Pod contains:
  - One **main container**
  - One **initContainer**
- No resource requests or limits are currently defined.

### Tasks

1. **Scale down** the Deployment **wordpress** to **0 replicas**.
2. Edit the Deployment so that:
   - CPU and memory resources are **evenly divided across all 3 Pods**
   - Each Pod has **fair and equal CPU and memory requests**
   - Add **sufficient overhead** to avoid node instability
3. Ensure that:
   - The **initContainer** and **main container** use **exactly the same resource requests and limits**
4. After completing the changes, **scale the Deployment back to 3 replicas**.

Do **not** modify any fields other than those required to complete this task.

---

## ✅ Solution

### Step 1: Scale the Deployment down

```bash
kubectl scale deployment wordpress --replicas=0
```

````

---

### Step 2: Decide resource allocation

Example fair distribution (exam-safe values):

Per Pod:

- CPU request: `200m`
- CPU limit: `300m`
- Memory request: `256Mi`
- Memory limit: `384Mi`

> These values leave headroom while ensuring fairness and stability.

---

### Step 3: Edit the Deployment

```bash
kubectl edit deployment wordpress
```

Add **identical resources** to **both initContainers and main containers**:

```yaml
resources:
  requests:
    cpu: "200m"
    memory: "256Mi"
  limits:
    cpu: "300m"
    memory: "384Mi"
```

✅ Ensure:

- Every container has the **same values**
- Requests ≤ limits

---

### Step 4: Scale back up

```bash
kubectl scale deployment wordpress --replicas=3
```

---

### Step 5: Verify

```bash
kubectl get pods
kubectl describe pod <pod-name>
```

Confirm:

- All Pods are **Running**
- Resource requests and limits are applied to **all containers**

---

## 🧠 Exam Memory Trick (Never Forget This)

Think in **3 layers**:

1. **Scale down** → avoid Pod churn
2. **Requests = fairness**, **Limits = protection**
3. **Init containers count too** → same rules apply

> If the question mentions _initContainers_, the exam **expects** you to configure them.
````
