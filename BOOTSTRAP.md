# Bootstrap Guide: Empty Nodes → Fully GitOps Cluster

This guide walks you through bootstrapping a complete GitOps-managed Kubernetes cluster from scratch.

## Prerequisites

- 3+ Ubuntu 22.04 LTS nodes (minimum: 1 control plane, 2 workers)
- SSH access to all nodes
- Root or sudo access
- Internet connectivity

## Phase 1: OS Layer (Manual Bootstrap)

### 1.1 Ubuntu Hardening

On all nodes:

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install essential packages
sudo apt install -y curl wget git vim net-tools

# Configure firewall
sudo ufw allow 22/tcp
sudo ufw allow 6443/tcp
sudo ufw allow 10250/tcp
sudo ufw allow 10259/tcp
sudo ufw allow 10257/tcp
sudo ufw enable

# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab
```

### 1.2 Install containerd

On all nodes:

```bash
# Install containerd
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system

sudo apt install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd
```

### 1.3 Install kubeadm, kubelet, kubectl

On all nodes:

```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

### 1.4 Initialize Control Plane

On the first control plane node:

```bash
# Initialize cluster
sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --control-plane-endpoint=<VIP_OR_LB_IP>:6443 \
  --upload-certs

# Setup kubeconfig
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### 1.5 Join Worker Nodes

On each worker node:

```bash
# Use the join command from kubeadm init output
sudo kubeadm join <CONTROL_PLANE_IP>:6443 \
  --token <TOKEN> \
  --discovery-token-ca-cert-hash sha256:<HASH>
```

### 1.6 Install CNI (Calico)

On control plane node:

```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.4/manifests/calico.yaml
```

### 1.7 Label Nodes

```bash
# Label nodes by role
kubectl label node <node-name> node.role=worker
kubectl label node <node-name> node.kong.gateway=true
kubectl label node <node-name> node.ceph.storage=true

# Add taints
kubectl taint node <kong-node> node.kong.gateway=true:NoSchedule
kubectl taint node <ceph-node> node.ceph.storage=true:NoSchedule
```

## Phase 2: Install ArgoCD

### 2.1 Install ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
```

### 2.2 Get ArgoCD Admin Password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### 2.3 Access ArgoCD UI

Port-forward or use Ingress:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Access: https://localhost:8080
- Username: `admin`
- Password: (from step 2.2)

## Phase 3: Bootstrap GitOps

### 3.1 Update Repository URL

Edit `clusters/prod/argocd-root.yaml`:

```yaml
source:
  repoURL: https://github.com/YOUR-USERNAME/YOUR-REPO.git
  targetRevision: main
```

### 3.2 Apply Root Application

```bash
# From your local machine with kubectl configured
kubectl apply -f clusters/prod/argocd-root.yaml
```

### 3.3 Verify Deployment

```bash
# Check ArgoCD applications
kubectl get applications -n argocd

# Watch sync status
argocd app list
argocd app get root
```

## Phase 4: Configure Secrets

### 4.1 Set up External Secrets

1. Configure SecretStore in `infra/external-secrets/secretstores.yaml`
2. Create ExternalSecret resources for:
   - Database credentials
   - TLS certificates
   - API keys

### 4.2 Vault Configuration

1. Initialize Vault (after it's deployed):
   ```bash
   kubectl exec -it vault-0 -n vault -- vault operator init
   ```

2. Unseal Vault:
   ```bash
   kubectl exec -it vault-0 -n vault -- vault operator unseal <key>
   ```

## Phase 5: Post-Deployment

### 5.1 Verify All Components

```bash
# Check namespaces
kubectl get namespaces

# Check pods
kubectl get pods --all-namespaces

# Check storage
kubectl get storageclass

# Check ingress
kubectl get ingress --all-namespaces
```

### 5.2 Access Services

- **ArgoCD**: `https://argocd.yourdomain.com`
- **Grafana**: `https://grafana.yourdomain.com`
- **Vault**: `https://vault.yourdomain.com`
- **Kong Manager**: `https://kong.yourdomain.com`

### 5.3 Configure DNS

Point your domain to Cloudflare Tunnel or LoadBalancer IP:
- Add DNS records for all services
- Configure Cloudflare Tunnel credentials

## Troubleshooting

### ArgoCD can't access repository
- Check repository URL and credentials
- Verify network connectivity
- Check ArgoCD repository secrets

### Applications stuck in "Progressing"
- Check pod logs: `kubectl logs -n <namespace> <pod-name>`
- Verify Helm chart versions
- Check resource quotas

### Storage not provisioning
- Verify Ceph cluster is healthy: `kubectl exec -it rook-ceph-tools -n rook-ceph -- ceph status`
- Check StorageClass: `kubectl get storageclass`
- Verify node labels and taints

## Next Steps

1. **Add your applications**: Follow the pattern in `apps/business/`
2. **Configure monitoring**: Set up alerting rules in Prometheus
3. **Set up backups**: Configure Velero or similar for cluster backups
4. **Security hardening**: Enable Pod Security Standards, Network Policies
5. **Multi-cluster**: Extend to staging/test environments

## Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Helm Documentation](https://helm.sh/docs/)

