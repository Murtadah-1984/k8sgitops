# Disaster Recovery Guide

This guide covers the disaster recovery process for the Kubernetes cluster with Rook-Ceph storage.

## Recovery Scenario: Complete Cluster Loss

When your cluster dies completely but **Ceph OSD disks are intact**, follow these steps to restore everything via GitOps.

## Prerequisites

- Ceph OSD nodes have **intact disks** with existing Ceph data
- Same hostnames, IPs, and VLANs as before
- Access to your GitOps repository
- Ansible playbooks configured

## Recovery Steps

### 1. Rebuild Kubernetes Cluster

Rebuild your control-plane and worker nodes using your existing K8s + CIS hardening scripts/Ansible playbooks.

**Important**: Use the same:
- Hostnames (`k8s-ceph-mon-01`, `k8s-ceph-01`, `k8s-ceph-02`)
- IP addresses
- VLAN configurations

### 2. Prepare Ceph Nodes (Ansible)

Run the Ceph node preparation playbook to ensure OS-level settings:

```bash
cd ansible
ansible-playbook -i inventory/hosts.ini playbooks/ceph-node-prepare.yml
```

**DO NOT** run `ceph-osd-disks.yml` - this would wipe your existing Ceph data!

### 3. Label Ceph Nodes

Label the Kubernetes nodes for Ceph placement:

```bash
ansible-playbook -i inventory/hosts.ini playbooks/ceph-label-nodes.yml
```

Or manually:
```bash
kubectl label node k8s-ceph-mon-01 ceph-mon=enabled ceph-osd=enabled --overwrite=true
kubectl label node k8s-ceph-02 ceph-osd=enabled --overwrite=true
kubectl label node k8s-ceph-03 ceph-osd=enabled --overwrite=true
```

### 4. Install ArgoCD

If ArgoCD is not already installed:

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Wait for ArgoCD to be ready:
```bash
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
```

### 5. Apply Root Application

Apply the root ArgoCD application to bootstrap GitOps:

```bash
kubectl apply -f clusters/prod/argocd-root.yaml
```

ArgoCD will automatically:
1. Deploy `rook-ceph-operator` (from Helm chart)
2. Deploy `rook-ceph-cluster` (from your Helm chart)
3. Rook will discover and reattach existing OSDs
4. Deploy all your applications and restore PVCs

### 6. Verify Recovery

Check Ceph cluster status:
```bash
kubectl -n rook-ceph get cephcluster
kubectl -n rook-ceph get pods
```

Check StorageClasses:
```bash
kubectl get storageclass
```

Check PVCs:
```bash
kubectl get pvc -A
```

Check Ceph cluster health (using toolbox):
```bash
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- ceph status
```

## Recovery Timeline

1. **K8s rebuild**: ~30-60 minutes (depends on your automation)
2. **Ansible prep**: ~5 minutes
3. **ArgoCD install**: ~5-10 minutes
4. **GitOps sync**: ~10-20 minutes (operator + cluster)
5. **OSD reattachment**: ~5-15 minutes (Rook discovers existing OSDs)
6. **App restoration**: Depends on number of apps

**Total**: ~1-2 hours for complete recovery

## Important Notes

### Preserving Ceph Data

- **DO**: Run `ceph-node-prepare.yml` to restore OS settings
- **DO NOT**: Run `ceph-osd-disks.yml` (wipes disks)
- **DO**: Ensure same hostnames and disk paths (`/dev/sdb`, `/dev/sdc`)
- **DO**: Label nodes correctly before deploying Rook

### Node Affinity

The Rook-Ceph cluster uses node affinity:
- **MONs**: Only on nodes with `ceph-mon=enabled`
- **OSDs**: Only on nodes with `ceph-osd=enabled`

Ensure labels are applied before ArgoCD syncs the cluster.

### Disk Paths

The Helm chart (`infra/ceph/rook-ceph-cluster/values.yaml`) specifies exact disk paths:
- `k8s-ceph-02`: `/dev/nvme0n1`
- `k8s-ceph-03`: `/dev/nvme0n1`

If your disk paths changed, update the values file before recovery.

## Troubleshooting

### OSDs Not Coming Up

1. Check node labels:
   ```bash
   kubectl get nodes --show-labels | grep ceph
   ```

2. Check disk paths match:
   ```bash
   kubectl -n rook-ceph get cephcluster rook-ceph -o yaml
   ```

3. Check OSD pods:
   ```bash
   kubectl -n rook-ceph get pods -l app=rook-ceph-osd
   kubectl -n rook-ceph logs -l app=rook-ceph-osd
   ```

### PVCs Not Binding

1. Verify StorageClass exists:
   ```bash
   kubectl get storageclass rook-ceph-block
   ```

2. Check CephBlockPool:
   ```bash
   kubectl -n rook-ceph get cephblockpool
   ```

3. Verify cluster is healthy:
   ```bash
   kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- ceph status
   ```

## Testing Recovery

To test your recovery process:

1. **Backup**: Document current state (PVCs, apps, Ceph health)
2. **Destroy**: Tear down K8s cluster (keep OSD disks!)
3. **Recover**: Follow steps above
4. **Verify**: Ensure all apps and data are restored

## Automation

Consider automating steps 2-5 in a recovery playbook:

```yaml
# ansible/playbooks/disaster-recovery.yml
- name: Disaster Recovery - Ceph Cluster
  hosts: localhost
  tasks:
    - name: Prepare Ceph nodes
      include_tasks: ceph-node-prepare.yml
      delegate_to: "{{ item }}"
      loop: "{{ groups['ceph'] }}"
    
    - name: Label nodes
      include_tasks: ceph-label-nodes.yml
    
    - name: Install ArgoCD (if needed)
      # ... kubectl apply ...
    
    - name: Apply root app
      # ... kubectl apply ...
```

