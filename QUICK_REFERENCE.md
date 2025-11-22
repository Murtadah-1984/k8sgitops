# Quick Reference Guide

## Repository Structure

```
gitops/
├── clusters/prod/          # ArgoCD Application manifests
├── infra/                  # Helm values + raw YAML
└── apps/                   # Application Helm values
```

## Common Commands

### ArgoCD CLI

```bash
# List all applications
argocd app list

# Get application status
argocd app get <app-name>

# Sync application
argocd app sync <app-name>

# Watch application
argocd app wait <app-name>

# Get application logs
argocd app logs <app-name>
```

### Kubernetes

```bash
# Check all namespaces
kubectl get namespaces

# Check pods in namespace
kubectl get pods -n <namespace>

# Check ArgoCD applications
kubectl get applications -n argocd

# Check storage classes
kubectl get storageclass

# Check ingress
kubectl get ingress --all-namespaces
```

### Ceph

```bash
# Access Ceph toolbox
kubectl exec -it rook-ceph-tools -n rook-ceph -- bash

# Check Ceph status
kubectl exec -it rook-ceph-tools -n rook-ceph -- ceph status

# List pools
kubectl exec -it rook-ceph-tools -n rook-ceph -- ceph osd pool ls
```

### Vault

```bash
# Initialize Vault
kubectl exec -it vault-0 -n vault -- vault operator init

# Unseal Vault
kubectl exec -it vault-0 -n vault -- vault operator unseal <key>

# Login to Vault
kubectl exec -it vault-0 -n vault -- vault login

# List secrets
kubectl exec -it vault-0 -n vault -- vault secrets list
```

## File Locations

### Update Repository URL
- `clusters/prod/argocd-root.yaml`
- All files in `clusters/prod/infra/`
- All files in `clusters/prod/apps/`

### Update Domain Names
- `infra/cloudflared/configmap.yaml`
- `infra/monitoring/values.yaml` (Grafana ingress)
- `infra/vault/values.yaml` (Vault ingress)
- Application values files in `apps/`

### Configure Secrets
- `infra/external-secrets/secretstores.yaml`
- Create ExternalSecret resources as needed

### Node Configuration
- `infra/node-pools/kong-nodes.yaml`
- `infra/node-pools/ceph-nodes.yaml`
- `infra/node-pools/worker-nodes.yaml`

## Adding a New Application

1. **Create values file**: `apps/business/my-app/values.yaml`
2. **Create ArgoCD Application**: `clusters/prod/apps/business/my-app.yaml`
3. **Commit and push** - ArgoCD will deploy automatically

Example Application manifest:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://charts.bitnami.com/bitnami
    chart: nginx
    targetRevision: 15.x.x
    helm:
      valueFiles:
        - ../../../../apps/business/my-app/values.yaml
  destination:
    namespace: business
    server: https://kubernetes.default.svc
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## Troubleshooting

### Application not syncing
```bash
# Check application status
argocd app get <app-name>

# Check application events
kubectl describe application <app-name> -n argocd

# Check pod logs
kubectl logs -n <namespace> <pod-name>
```

### Helm chart errors
```bash
# Dry-run Helm template
helm template <release-name> <chart> -f values.yaml

# Check chart version
helm search repo <chart-name>
```

### Storage issues
```bash
# Check PVCs
kubectl get pvc --all-namespaces

# Check storage class
kubectl get storageclass

# Check Ceph health
kubectl exec -it rook-ceph-tools -n rook-ceph -- ceph status
```

## URLs (After Configuration)

- **ArgoCD**: `https://argocd.arajeez-cloud.com`
- **Grafana**: `https://grafana.arajeez-cloud.com`
- **Vault**: `https://vault.arajeez-cloud.com`
- **Kong Manager**: `https://kong.arajeez-cloud.com`

## Important Notes

- **Never commit secrets** to Git
- **Always use External Secrets Operator** for sensitive data
- **Pin chart versions** in production
- **Test changes** in staging/test environment first
- **Monitor ArgoCD** for sync status

