Question
A user accidentally deleted the MariaDB Deployment in the mariadb namespace.
The deployment was previously configured to use persistent storage.
Your responsibility is to restore the application while preserving the existing data by reusing the available ==PersistentVolume==.

Task
A ==PersistentVolume== already exists in the cluster and is retained for reuse.
There is only one PV available.

Complete the following tasks:

Create a PersistentVolumeClaim named **mariadb** in the **mariadb** namespace with the following specifications:
Access Mode: **ReadWriteOnce**
Storage: **250Mi**

Edit the MariaDB Deployment manifest located at: `~/mariadb-deploy.yaml`

Configure the deployment so that it uses the PVC created in the previous step.
Apply the updated Deployment manifest to the cluster.
Ensure the MariaDB Deployment is running and stable.

==Note==
The existing PersistentVolume must be reused by the new PersistentVolumeClaim.

Video Link:
https://youtu.be/aXvvc1EB1zg