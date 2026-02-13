# Question 02 – Sidecar Container (CKA Exam Style)

## Context

An existing Deployment named **`wordpress`** is running in the cluster.

You must update this Deployment by adding a **sidecar container** that tails an application log file produced in `/var/log`.

---

## Task

Update the existing **`wordpress` Deployment** by adding a sidecar container with the following requirements:

### Sidecar Container Requirements

- **Container name:** `sidecar`
- **Image:** `busybox:stable`
- **Command:**
  ```sh
  /bin/sh -c "tail -f /var/log/wordpress.log"
  ```

````

### Volume Requirements

* Use a **shared volume** mounted at **`/var/log`**
* The log file **`wordpress.log`** must be accessible to **both containers**
* The two containers must share the same log directory using the same volume mount

---

## Constraints

* Do **NOT** recreate the Deployment
* Do **NOT** change the Deployment name
* Do **NOT** change existing container images/commands (except adding mounts if needed)
* Ensure the Deployment remains functional after the update

---

## Validation

* Pod should be **Running**
* Sidecar should continuously output log entries from `/var/log/wordpress.log`

---

# ✅ Solution (Exam-Style)

## 1) Inspect the current Deployment

```bash
kubectl get deploy wordpress -o wide
kubectl get deploy wordpress -o yaml > wordpress.yaml
```

Quickly check current containers:

```bash
kubectl get deploy wordpress -o jsonpath='{.spec.template.spec.containers[*].name}{"\n"}'
```

---

## 2) Edit the Deployment (fastest in exam)

```bash
kubectl edit deploy wordpress
```

### Add a shared volume (recommended: `emptyDir`)

Under:

```yaml
spec:
  template:
    spec:
```

Add:

```yaml
      volumes:
        - name: varlog
          emptyDir: {}
```

### Add volumeMount to the existing main container

Find the existing container (likely `wordpress`) and add:

```yaml
        volumeMounts:
          - name: varlog
            mountPath: /var/log
```

> If `volumeMounts` already exists, just append the entry.

### Add the sidecar container

Under `containers:` add a second container:

```yaml
      containers:
        - name: wordpress
          # existing fields...
          volumeMounts:
            - name: varlog
              mountPath: /var/log

        - name: sidecar
          image: busybox:stable
          command:
            - /bin/sh
            - -c
            - "tail -f /var/log/wordpress.log"
          volumeMounts:
            - name: varlog
              mountPath: /var/log
```

Save and exit.

---

## 3) Wait for rollout

```bash
kubectl rollout status deploy wordpress
```

---

## 4) Verify the pod has 2 containers

```bash
kubectl get pods -l app=wordpress
```

If no label exists, just list pods and find the wordpress pod:

```bash
kubectl get pods
```

Then:

```bash
kubectl describe pod <wordpress-pod-name> | grep -A2 "Containers:"
```

---

## 5) Validate the sidecar is tailing the log

```bash
kubectl logs <wordpress-pod-name> -c sidecar --tail=50
```

If the log file doesn’t exist yet, create it from the main container to confirm the shared mount works:

```bash
kubectl exec -it <wordpress-pod-name> -c wordpress -- sh -c 'echo "hello from wordpress" >> /var/log/wordpress.log'
kubectl logs <wordpress-pod-name> -c sidecar --tail=20
```

You should see:

```
hello from wordpress
```

---

# ✅ Reference Final YAML Snippet (What Your Deployment Must Contain)

```yaml
spec:
  template:
    spec:
      volumes:
        - name: varlog
          emptyDir: {}

      containers:
        - name: wordpress
          # ...existing config
          volumeMounts:
            - name: varlog
              mountPath: /var/log

        - name: sidecar
          image: busybox:stable
          command:
            - /bin/sh
            - -c
            - "tail -f /var/log/wordpress.log"
          volumeMounts:
            - name: varlog
              mountPath: /var/log
```

---

## Notes (Exam Mindset)

* `emptyDir` is perfect for “share data between containers in the same Pod”.
* The sidecar won’t output anything until the log file exists and gets new lines—so writing a test line is a valid verification step.

````
