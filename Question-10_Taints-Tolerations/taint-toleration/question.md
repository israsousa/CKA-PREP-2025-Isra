# Practice Question — Taints & Tolerations (Exam Style)

There is a worker node named `node01` in the cluster.

## Tasks

1. Add a taint to `node01` so that **normal Pods cannot be scheduled** on it:

- key: `IT`
- value: `codegenitor`
- effect: `NoSchedule`

2. Create a Pod named `taint-test` in the `default` namespace that:

- Uses image `busybox:stable`
- Runs command: `sleep 3600`
- Has the correct toleration for the taint
- Is scheduled onto `node01`

## Verification

- `node01` must show the taint `IT=codegenitor:NoSchedule`
- Pod `taint-test` must be `Running` on `node01`

---

# ✅ Solution

## 1) Add the taint to node01

```bash
kubectl taint node node01 IT=codegenitor:NoSchedule
```

Verify:

```bash
kubectl describe node node01 | grep -i taint -A3
# or
kubectl get node node01 -o jsonpath='{.spec.taints}' ; echo
```

## 2) Create the Pod with toleration + force it onto node01

Create the Pod manifest:

```bash
cat > taint-test.yaml <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: taint-test
  namespace: default
spec:
  nodeName: node01
  tolerations:
    - key: "IT"
      operator: "Equal"
      value: "codegenitor"
      effect: "NoSchedule"
  containers:
    - name: taint-test
      image: busybox:stable
      command: ["sh", "-c", "sleep 3600"]
EOF
```

Apply:

```bash
kubectl apply -f taint-test.yaml
```

## 3) Verify

```bash
kubectl get pod taint-test -o wide
kubectl get node node01 -o jsonpath='{range .spec.taints[*]}{.key}{"="}{.value}{":"}{.effect}{"\n"}{end}'
```

Expected:

- Pod `taint-test` is `Running`
- `NODE` column shows `node01`
- Taint output includes `IT=codegenitor:NoSchedule`
