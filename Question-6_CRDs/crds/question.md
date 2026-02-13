# 🧪 Question — CRDs (cert-manager)

**CKA Exam Style**

## Context

**cert-manager** is already installed in the Kubernetes cluster.

---

## Tasks

### Task 1

Create a list of all **cert-manager CustomResourceDefinitions (CRDs)** and save the output to:

```
~/resources.yaml
```

Requirements:

- Use `kubectl`
- Keep **default kubectl output formatting**
- Do **not** manually edit the file

---

### Task 2

Using `kubectl`, extract the **documentation** for the **`subject`** specification field of the **Certificate** Custom Resource and save the output to:

```
~/subject.yaml
```

Requirements:

- Use `kubectl`
- Any output format supported by `kubectl` is acceptable

---

# ✅ Solution

---

## ✅ Task 1 — List cert-manager CRDs

### Correct command (exam-safe)

```bash
kubectl get crd | grep cert-manager.io > ~/resources.yaml
```

### Why this is correct

- `kubectl get crd` → default output format
- `grep cert-manager.io` → matches all cert-manager CRDs reliably
- Output is redirected **exactly** as requested

📌 Example CRDs you’ll see:

- `certificates.cert-manager.io`
- `issuers.cert-manager.io`
- `clusterissuers.cert-manager.io`
- `certificaterequests.cert-manager.io`

---

## ✅ Task 2 — Extract documentation for `spec.subject`

The **Certificate** CRD belongs to the API group:

```
cert-manager.io
```

### Correct command

```bash
kubectl explain certificate.spec.subject --api-version=cert-manager.io/v1 > ~/subject.yaml
```

---

## ✅ Verify files (optional but safe)

```bash
ls -l ~/resources.yaml ~/subject.yaml
```

---

# 📌 What the examiner is testing

| Task   | Skill                            |
| ------ | -------------------------------- |
| Task 1 | CRD discovery & filtering        |
| Task 2 | CRD field introspection          |
| Both   | Correct use of `kubectl explain` |

---

# 🧠 Exam Notes (IMPORTANT)

### ✔ Correct

- `kubectl explain` works for **CRDs**
- You must specify `--api-version` for CRDs
- Redirecting output is acceptable

### ❌ Common mistakes

| Mistake                      | Result        |
| ---------------------------- | ------------- |
| `grep cert-manager` only     | May miss CRDs |
| Forgetting `--api-version`   | Explain fails |
| Using `kubectl describe crd` | Wrong task    |
| Editing output manually      | Risky         |

---

# 🧠 One-line exam rule (GOLD)

> **For CRDs: `kubectl explain <kind>.<field> --api-version=<group/version>`**
