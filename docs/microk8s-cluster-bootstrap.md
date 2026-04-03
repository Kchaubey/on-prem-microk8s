# MicroK8s Cluster Bootstrap (On-Prem)

This runbook is the baseline for creating a production-ready MicroK8s cluster on on-prem infrastructure.

## 1) Reference Topology

- Environment: on-prem bare metal or VM
- Kubernetes distro: MicroK8s (snap)
- Ingress: NGINX Ingress Controller (MicroK8s addon)
- Storage: hostpath storage class (or replace with NFS/Ceph in production)
- Deployment model: Helm blue-green chart per project

## 2) Host Prerequisites

- Ubuntu 22.04/24.04 LTS recommended
- Minimum per node:
  - 4 vCPU
  - 8 GB RAM
  - 60+ GB disk
- Time sync enabled (`timedatectl` should show `NTP service: active`)
- Required network access between nodes

Example firewall openings (adjust to your network policy):

- `16443/tcp` Kubernetes API server
- `10250/tcp` kubelet
- `25000/tcp` MicroK8s cluster-agent
- `19001/tcp` dqlite
- `8472/udp` VXLAN (if Calico VXLAN is used)
- `4789/udp` VXLAN (depending on CNI mode)

## 3) Base OS Hardening

```bash
sudo swapoff -a
sudo sed -ri '/\sswap\s/s/^#?/#/' /etc/fstab
sudo apt-get update
sudo apt-get install -y curl jq net-tools ca-certificates
```

Optional but strongly recommended:

```bash
sudo timedatectl set-ntp true
sudo hostnamectl set-hostname <node-name>
```

## 4) Install MicroK8s

```bash
sudo snap install microk8s --classic --channel=1.30/stable
sudo usermod -a -G microk8s $USER
sudo chown -f -R "$USER" ~/.kube
newgrp microk8s

microk8s status --wait-ready
microk8s kubectl get nodes -o wide
```

## 5) Enable Core Addons

```bash
microk8s enable dns ingress metrics-server hostpath-storage helm3
```

If you need LoadBalancer IPs on LAN, enable MetalLB:

```bash
microk8s enable metallb:10.120.130.60-10.120.130.80
```

Use an address pool that belongs to your DMZ/LAN segment and is not used by DHCP.

## 6) Export kubeconfig for CI/CD

```bash
mkdir -p ~/.kube
microk8s config > ~/.kube/config
chmod 600 ~/.kube/config

kubectl get nodes
kubectl get pods -A
```

For CI variables:

```bash
# API endpoint (usually https://<control-plane-ip>:16443)
kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'

# CA cert (base64)
kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' ; echo

# Service-account token should be generated from a least-privilege account
# instead of copying your personal kubeconfig token.
```

## 7) Namespace and Secret Baseline

```bash
kubectl create namespace production --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret docker-registry registry-credentials \
  --docker-server="<registry-url>" \
  --docker-username="<registry-user>" \
  --docker-password="<registry-password>" \
  -n production \
  --dry-run=client -o yaml | kubectl apply -f -
```

## 8) Optional Multi-Node Expansion

On control-plane node:

```bash
microk8s add-node
```

On worker node (using the printed token/command):

```bash
microk8s join <control-plane-ip>:25000/<token>
```

Validate:

```bash
microk8s kubectl get nodes -o wide
```

## 9) Post-Bootstrap Validation Checklist

```bash
microk8s status --wait-ready
kubectl get nodes
kubectl get pods -n ingress
kubectl get pods -n kube-system
kubectl get sc
kubectl top nodes
```

If anything fails, use the troubleshooting playbook: [`troubleshooting.md`](./troubleshooting.md).
