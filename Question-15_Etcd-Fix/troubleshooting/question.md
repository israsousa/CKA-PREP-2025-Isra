# Practice Question — Control Plane Troubleshooting (Exam Style)

After a cluster migration, the **control plane is not functional**.

The `kube-apiserver` on the control plane node is **not coming up**.

## Given Information

- Before the migration:
  - `etcd` was **external** and running in **HA mode**
- After the migration:
  - `kube-apiserver` is incorrectly configured
  - It is pointing to the **etcd peer port `2380` instead of client port `2379`**

You must fix the issue so that the Kubernetes control plane becomes healthy again.

> You are working directly on the control plane node.

---

## Tasks

1. Identify why the `kube-apiserver` is failing
2. Fix the incorrect etcd configuration
3. Ensure the `kube-apiserver` starts successfully
4. Verify that the cluster is functional

---

## Expected Result

- `kube-apiserver` Pod is **Running**
- `kubectl get nodes` works successfully
- Control plane components are healthy

---

# ✅ Solution

## 1) Check kube-apiserver status

```bash
kubectl get pods -n kube-system
```

If the API server is down, this command may fail.

Check static pod logs instead:

```bash
crictl ps | grep kube-apiserver
crictl logs <kube-apiserver-container-id>
```

You will see an error related to **etcd connection failure**.

---

## 2) Edit kube-apiserver static manifest

The kube-apiserver runs as a **static Pod**.

Open the manifest:

```bash
vi /etc/kubernetes/manifests/kube-apiserver.yaml
```

Locate the `--etcd-servers` flag.

### ❌ Incorrect configuration (peer port)

```yaml
- --etcd-servers=https://<ETCD_IP>:2380
```

### ✅ Correct configuration (client port)

```yaml
- --etcd-servers=https://<ETCD_IP>:2379
```

Save and exit.

---

## 3) Wait for kubelet to restart kube-apiserver

Kubelet automatically reloads static Pods.

Check:

```bash
crictl ps | grep kube-apiserver
```

Wait until the container is running.

---

## 4) Verify cluster health

```bash
kubectl get nodes
kubectl get pods -n kube-system
```

You should now see:

- API server responding
- Nodes in `Ready` state
- Core components running

---

## Key Exam Notes

- **Port 2379** → etcd **client** port (used by kube-apiserver)
- **Port 2380** → etcd **peer** port (used only between etcd members)
- Static Pods live in:

  ```
  /etc/kubernetes/manifests/
  ```

- Editing the file is enough — **no restart command needed**

---

## Exam Tip

If `kubectl` does not work:

- Use `crictl`
- Inspect static Pod manifests
- Always check **ports**, **cert paths**, and **endpoints**

This is a **high-probability CKA exam scenario**.
