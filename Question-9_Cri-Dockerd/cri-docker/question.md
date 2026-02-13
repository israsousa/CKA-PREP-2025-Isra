# CKA Practice Question – CRI-Dockerd Setup (Codegenitor)

## Question – Configure CRI-Dockerd

You are configuring a Kubernetes node where **Docker is installed**, but Kubernetes cannot communicate with it because the **CRI shim is missing**.

Your task is to install and configure **cri-dockerd** so that Kubernetes can use Docker as the container runtime.

All required files are already available on the node.

---

### Provided Information

- The Debian package is available at:

```

/root/cri-dockerd_0.3.9.3-0.ubuntu-jammy_amd64.deb

```

- Kubernetes requires certain kernel parameters to be set for networking and conntrack.

---

### Tasks

1. Install the `cri-dockerd` Debian package using `dpkg`.
2. Enable and start the `cri-docker` service.
3. Configure the following system parameters so they **persist across reboots**:

   - `net.bridge.bridge-nf-call-iptables = 1`
   - `net.ipv6.conf.all.forwarding = 1`
   - `net.ipv4.ip_forward = 1`
   - `net.netfilter.nf_conntrack_max = 131072`

4. Apply the system configuration.
5. Verify that the `cri-docker` service is running.

⚠️ **Constraints**

- Do not reboot the node.
- Do not reinstall Kubernetes.
- Use the provided package and system configuration only.

---

## ✅ Solution

### 1. Install cri-dockerd

```bash
dpkg -i /root/cri-dockerd_0.3.9.3-0.ubuntu-jammy_amd64.deb
```

---

### 2. Enable and start the service

```bash
systemctl enable --now cri-docker
```

Verify:

```bash
systemctl status cri-docker
```

---

### 3. Configure required sysctl parameters

Create the configuration file:

```bash
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv6.conf.all.forwarding = 1
net.ipv4.ip_forward = 1
net.netfilter.nf_conntrack_max = 131072
EOF
```

---

### 4. Apply the system settings

```bash
sysctl --system
```

---

### 5. Verification

Confirm values are applied:

```bash
sysctl net.bridge.bridge-nf-call-iptables
sysctl net.ipv4.ip_forward
sysctl net.ipv6.conf.all.forwarding
sysctl net.netfilter.nf_conntrack_max
```

Confirm CRI socket exists:

```bash
ls /var/run/cri-dockerd.sock
```

---

## ✅ Expected Result

- `cri-docker` service is running
- Required kernel parameters are set and persistent
- Kubernetes can communicate with Docker using CRI-Dockerd

---

**End of Question**
