# Kubernetes GitOps Repository

Production-ready GitOps repository using **ArgoCD** and **Helm** for managing a complete Kubernetes platform.

## Architecture

This repository follows a **pure Helm-centric GitOps pattern** with clear separation of concerns:

- **100% Helm charts** for all workloads and infrastructure
- **Raw YAML only** where Helm is not possible (namespaces, node labels/taints, CRDs)
- **App-of-Apps pattern** for hierarchical application management
- **Cluster-per-folder** structure (prod / staging / test)

## Repository Structure

```
gitops/
├── clusters/                    # ArgoCD Application manifests
│   └── prod/
│       ├── argocd-root.yaml     # ROOT app-of-apps (apply manually)
│       ├── infra/               # Infrastructure applications
│       └── apps/                # Business & platform applications
│
├── infra/                       # Helm values + raw YAML
│   ├── kong/                    # Kong Gateway
│   ├── ceph/                    # Rook Ceph storage
│   ├── monitoring/              # Prometheus + Grafana
│   ├── vault/                   # HashiCorp Vault
│   ├── cloudflared/             # Cloudflare Tunnel
│   ├── external-secrets/        # External Secrets Operator
│   ├── namespaces/              # Namespace definitions
│   └── node-pools/              # Node labels & taints
│
└── apps/                        # Application Helm values
    ├── business/                # Business applications
    └── platform/                # Platform applications
```

## Quick Start

### Prerequisites

1. Kubernetes cluster (1.24+)
2. ArgoCD installed
3. kubectl configured with cluster access

### Bootstrap

1. **Update repository URL** in `clusters/prod/argocd-root.yaml`:
   ```yaml
   repoURL: https://github.com/YOUR/repo.git
   ```

2. **Apply the root application**:
   ```bash
   kubectl apply -f clusters/prod/argocd-root.yaml
   ```

3. **ArgoCD will automatically deploy** all applications recursively under `clusters/prod/`

## Infrastructure Components

### Kong Gateway
- **Chart**: `charts.konghq.com/kong`
- **Namespace**: `kong`
- **Node Affinity**: Dedicated nodes with label `node.kong.gateway: "true"`

### Ceph Storage (Rook)
- **Operator Chart**: `charts.rook.io/release/rook-ceph`
- **Cluster Chart**: Custom Helm chart at `infra/ceph/rook-ceph-cluster/`
- **Namespace**: `rook-ceph`
- **Node Labels**: 
  - MON nodes: `ceph-mon=enabled`
  - OSD nodes: `ceph-osd=enabled`
- **Node Preparation**: Ansible playbooks in `ansible/playbooks/`

### Monitoring Stack
- **Chart**: `prometheus-community.github.io/helm-charts/kube-prometheus-stack`
- **Namespace**: `monitoring`
- **Components**: Prometheus, Grafana, AlertManager

### Vault
- **Chart**: `helm.releases.hashicorp.com/vault`
- **Namespace**: `vault`
- **Mode**: HA with Consul backend

### Cloudflare Tunnel
- **Type**: Raw YAML (no official Helm chart)
- **Namespace**: `cloudflared`
- **Purpose**: Secure ingress to cluster services

### External Secrets Operator
- **Chart**: `charts.external-secrets.io/external-secrets`
- **Namespace**: `external-secrets-system`
- **Purpose**: Sync secrets from external secret managers

## Configuration

### Before Deployment

1. **Update repository URLs** in all Application manifests:
   - Replace `https://github.com/YOUR/repo.git` with your actual repository

2. **Configure domain names** in:
   - `infra/cloudflared/configmap.yaml`
   - Ingress configurations in Helm values files

3. **Set up secrets** via External Secrets Operator:
   - Database credentials
   - TLS certificates
   - API keys

4. **Prepare Ceph nodes** (if using Ceph):
   - Edit `ansible/inventory/hosts.ini` with your node IPs
   - Run `ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/ceph-node-prepare.yml`
   - Run `ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/ceph-label-nodes.yml`
   - **WARNING**: Only run `ceph-osd-disks.yml` on fresh disks (wipes data!)

5. **Configure node labels**:
   - Apply node labels/taints from `infra/node-pools/` to your nodes
   - Or update node selectors in Helm values if using different labels

### Node Pool Configuration

Nodes should be labeled and tainted according to their role:

- **Kong nodes**: `node.kong.gateway: "true"` with taint
- **Ceph MON nodes**: `ceph-mon=enabled` (no taint)
- **Ceph OSD nodes**: `ceph-osd=enabled` (no taint)
- **Worker nodes**: `node.role: "worker"` (no taint)

Apply node configurations:
```bash
kubectl apply -f infra/node-pools/
```

## Adding Applications

### Business Applications

1. Create directory: `apps/business/your-app/`
2. Add `values.yaml` with Helm values
3. Create ArgoCD Application: `clusters/prod/apps/business/your-app.yaml`
4. Commit and push - ArgoCD will deploy automatically

### Platform Applications

Same process, but under `apps/platform/` and `clusters/prod/apps/platform/`

## GitOps Workflow

1. **Make changes** to Helm values or Application manifests
2. **Commit and push** to Git repository
3. **ArgoCD detects changes** and syncs automatically (if auto-sync enabled)
4. **Monitor** via ArgoCD UI or CLI

## Manual Sync

If auto-sync is disabled:
```bash
argocd app sync <app-name>
```

## Best Practices

1. **Always use Helm** for applications - avoid raw YAML unless necessary
2. **Separate concerns**: infra vs apps, business vs platform
3. **Use External Secrets** for all sensitive data
4. **Version pinning**: Pin chart versions in Application manifests
5. **Resource limits**: Always set resource requests/limits
6. **Node affinity**: Use dedicated nodes for critical workloads

## Troubleshooting

### Application not syncing
- Check ArgoCD application status: `argocd app get <app-name>`
- Verify repository access and credentials
- Check Application manifest syntax

### Helm chart errors
- Verify chart repository is accessible
- Check Helm values file syntax
- Review chart version compatibility

### Node affinity issues
- Ensure nodes are properly labeled
- Verify tolerations match taints
- Check node selector in Helm values

## Documentation

- [Kong Gateway](infra/kong/README.md)
- [Applications](apps/README.md)
- [Disaster Recovery](DISASTER_RECOVERY.md) - Complete cluster recovery guide
- [Ansible Playbooks](ansible/README.md) - Ceph node preparation

## License

[Your License Here]

