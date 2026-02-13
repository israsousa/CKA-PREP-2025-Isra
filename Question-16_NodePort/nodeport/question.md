## Question 16 – NodePort Service Exposure

There is an existing Deployment named `nodeport-deployment` in the **default namespace**.

The Deployment is currently running but is **not exposed externally**.

### Tasks

1. Update the Deployment so that the application listens on:

   - Container port: `80`
   - Protocol: `TCP`

2. Create a Service named `nodeport-service` with the following requirements:

   - Type: `NodePort`
   - Expose container port `80`
   - Protocol: `TCP`

3. Configure the Service so that individual Pods can be accessed externally using a NodePort.

4. Do **not** modify the Deployment name or namespace.

5. Ensure the Service is correctly routing traffic to the Pods.

---

### Verification

You should be able to confirm the setup by running:

```bash
kubectl get svc nodeport-service
kubectl describe svc nodeport-service
```
