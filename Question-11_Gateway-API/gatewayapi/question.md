# Question – Gateway API Migration

You are working in a Kubernetes cluster that currently exposes a web application using an **Ingress** resource.

### Existing State

- A Kubernetes **Ingress** resource named **web**
- The Ingress exposes a web application over **HTTPS**
- The hostname used by the Ingress is:

  gateway.web.k8s.local

- A **GatewayClass** named **nginx-class** already exists in the cluster
- TLS configuration is already defined on the existing Ingress
- The backend Service and routing rules must remain unchanged

### Task

You must **migrate the existing Ingress configuration to the Kubernetes Gateway API**, while preserving the same behavior.

### Requirements

1. Create a **Gateway** resource named **web-gateway**

   - Use **GatewayClass `nginx-class`**
   - Configure a **TLS listener** on port **443**
   - Use hostname: `gateway.web.k8s.local`
   - Reuse the existing TLS configuration from the Ingress

2. Create an **HTTPRoute** resource named **web-route**
   - Attach it to the **web-gateway**
   - Use hostname: `gateway.web.k8s.local`
   - Preserve the existing routing rules from the Ingress
   - Route traffic to the same backend Service as the Ingress

### Notes

- Do NOT modify the existing Ingress
- Do NOT change backend Services or ports
- Only Gateway API resources should be created

````

---

# ✅ Solution

---

## Step 1: Inspect the existing Ingress

```bash
kubectl get ingress web -o yaml
````

From this, identify:

- TLS secret name
- Backend Service name
- Backend Service port
- Path rules

(These values must be reused exactly.)

---

## Step 2: Create the Gateway

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: web-gateway
spec:
  gatewayClassName: nginx-class
  listeners:
    - name: https
      hostname: gateway.web.k8s.local
      port: 443
      protocol: HTTPS
      tls:
        mode: Terminate
        certificateRefs:
          - kind: Secret
            name: web-tls
```

Apply it:

```bash
kubectl apply -f gateway.yaml
```

> `web-tls` must match the TLS secret used by the original Ingress.

---

## Step 3: Create the HTTPRoute

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: web-route
spec:
  parentRefs:
    - name: web-gateway
  hostnames:
    - gateway.web.k8s.local
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: web-service
          port: 80
```

Apply it:

```bash
kubectl apply -f httproute.yaml
```

> `web-service` and `port 80` must match the backend defined in the Ingress.

---

## Step 4: Verify

```bash
kubectl get gateway
kubectl get httproute
```

Optional validation:

```bash
kubectl describe gateway web-gateway
kubectl describe httproute web-route
```

---

## 🧠 Exam Memory Rule (Burn This In)

**Ingress → Gateway API mapping**

| Ingress Concept | Gateway API Equivalent |
| --------------- | ---------------------- |
| Ingress         | Gateway + HTTPRoute    |
| ingressClass    | gatewayClassName       |
| tls.secretName  | certificateRefs        |
| rules.host      | listeners.hostname     |
| backend.service | backendRefs            |

> **Never modify the Ingress** — migrate beside it.
