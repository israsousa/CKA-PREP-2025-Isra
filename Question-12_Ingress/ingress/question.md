# Question – Ingress Resource (codegenitor)

Create a new Ingress resource named **echo** in the **echo-sound** namespace.

## Context

The following resources already exist:

- Namespace: `echo-sound`
- Deployment: `echo` (serves HTTP on port `8080`)
- Service: `echo-service` (type `NodePort`, port `8080`)

## Tasks

1. Expose the Deployment using the existing Service **echo-service** on the URL:

   - Host: `example.org`
   - Path: `/echo`

2. Create an Ingress named **echo** in namespace **echo-sound** so that:

   - `http://example.org/echo` routes to Service `echo-service` on port `8080`
   - A valid `pathType` is used

3. Verify the endpoint returns HTTP **200** using:

```bash
curl -o /dev/null -s -w "%{http_code}\n" http://example.org/echo
```

---

# Solution

## 1) Confirm existing resources

```bash
kubectl get deploy,svc -n echo-sound
```

## 2) Create the Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: echo
  namespace: echo-sound
spec:
  rules:
    - host: example.org
      http:
        paths:
          - path: /echo
            pathType: Prefix
            backend:
              service:
                name: echo-service
                port:
                  number: 8080
```

Apply it:

```bash
kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: echo
  namespace: echo-sound
spec:
  rules:
    - host: example.org
      http:
        paths:
          - path: /echo
            pathType: Prefix
            backend:
              service:
                name: echo-service
                port:
                  number: 8080
EOF
```

## 3) Verify

```bash
kubectl get ingress -n echo-sound
kubectl describe ingress echo -n echo-sound
curl -o /dev/null -s -w "%{http_code}\n" http://example.org/echo
```

Expected output: `200`

```

```
