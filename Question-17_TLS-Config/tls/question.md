# CKA Practice — TLS Configuration (Exam-Style)

> **Context**
>
> - Use the current context.
> - Work only in the namespace mentioned.
> - Do not change resource names unless the task says so.
> - Verify your work.

---

## QUESTION: TLS Configuration (NGINX + ConfigMap)

There is an existing Deployment called **nginx-static** in the **nginx-static** namespace.

- The Deployment uses a **ConfigMap** that currently allows **TLSv1.2 and TLSv1.3**
- A TLS **Secret** already exists and is used by NGINX
- A Service named **nginx-static** in the same namespace is exposing the Deployment

### Tasks

1. Update the ConfigMap so NGINX supports **TLSv1.3 only** (TLSv1.2 must be removed).
2. Add the **ClusterIP** of the Service `nginx-static` to `/etc/hosts` with this name:

```

codegenitor.k8s.local

```

3. Verify the results with:

```bash
curl --tls-max 1.2 https://codegenitor.k8s.local -k   # TLSv1.2 should NOT work
curl --tlsv1.3  https://codegenitor.k8s.local -k      # TLSv1.3 should work
```

---

## ✅ Solution

### 1) Update the ConfigMap to TLSv1.3 only

```bash
kubectl -n nginx-static edit configmap nginx-config
```

Find the line like:

```nginx
ssl_protocols TLSv1.2 TLSv1.3;
```

Change it to:

```nginx
ssl_protocols TLSv1.3;
```

### 2) Restart NGINX so it loads the new config

```bash
kubectl -n nginx-static rollout restart deploy/nginx-static
kubectl -n nginx-static rollout status deploy/nginx-static
```

### 3) Add Service IP to /etc/hosts

```bash
SVC_IP=$(kubectl -n nginx-static get svc nginx-static -o jsonpath='{.spec.clusterIP}')
echo "$SVC_IP codegenitor.k8s.local" | sudo tee -a /etc/hosts
```

### 4) Verify

```bash
curl --tls-max 1.2 https://codegenitor.k8s.local -k
curl --tlsv1.3  https://codegenitor.k8s.local -k
```

If the first command fails and the second command works, you are done.
