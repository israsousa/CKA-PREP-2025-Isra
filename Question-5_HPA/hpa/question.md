# Question – CRDs (cert-manager)

cert-manager is installed in the cluster.

## Tasks

1. Create a list of all **cert-manager** CustomResourceDefinitions (CRDs) and save the output to:

   `~/resources.yaml`

   Use `kubectl` to list CRDs and keep the default output formatting supported by `kubectl`.

2. Using `kubectl`, extract the documentation for the **subject** specification field of the **Certificate** Custom Resource and save the output to:

   `~/subject.yaml`

   You may use any output format that `kubectl` supports.

---

## Solution

### Task 1

```bash
kubectl get crd | grep cert-manager > ~/resources.yaml
```

````

### Task 2

```bash
kubectl explain certificate.spec.subject --recursive > ~/subject.yaml
```
````
