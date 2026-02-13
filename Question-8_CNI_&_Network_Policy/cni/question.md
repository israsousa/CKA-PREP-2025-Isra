# Question 11 – Container Network Interface (CNI)

## Context

You are managing a Kubernetes cluster that does not yet have a Container Network Interface (CNI) configured.

The cluster must support:

- Pod-to-Pod communication across nodes
- NetworkPolicy enforcement

You are required to install **one CNI of your choice** using the provided manifests.

---

## Requirements

Install and configure **one** of the following CNIs:

### Option 1: Flannel

- Version: v0.26.1
- Manifest:
  https://github.com/flannel-io/flannel/releases/download/v0.26.1/kube-flannel.yml

### Option 2: Calico

- Version: v3.28.2
- Manifest:
  https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/tigera-operator.yaml

---

## The installed CNI must:

1. Allow Pod-to-Pod communication across all nodes
2. Support Kubernetes NetworkPolicy enforcement
3. Be installed directly from the provided manifest

---

## Tasks

1. Choose **either Flannel or Calico**
2. Install the selected CNI using `kubectl`
3. Verify that all CNI-related Pods are running successfully

---

## Solution

### Example Solution (Calico)

```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/tigera-operator.yaml
```

````

Verify installation:

```bash
kubectl get pods -n kube-system
```

Ensure that all Calico-related Pods are in `Running` state.

---

### Example Solution (Flannel)

```bash
kubectl apply -f https://github.com/flannel-io/flannel/releases/download/v0.26.1/kube-flannel.yml
```

Verify installation:

```bash
kubectl get pods -n kube-system
```

Ensure that all Flannel Pods are in `Running` state.

---

## Verification

- Pods can communicate across nodes
- NetworkPolicies can be created and enforced
- No CNI Pods are in `CrashLoopBackOff` or `Pending` state

✅ **Task complete when the cluster networking is functional and stable**

```

```
````
