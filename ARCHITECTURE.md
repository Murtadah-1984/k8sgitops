# Platform Architecture

## Overview

This GitOps repository manages a complete Kubernetes platform using ArgoCD and Helm, following industry best practices for production deployments.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Git Repository                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  clusters/   │  │    infra/    │  │    apps/     │     │
│  │  (ArgoCD)    │  │  (Helm vals) │  │  (Helm vals) │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                          │
                          │ Git Push
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                    ArgoCD (GitOps Engine)                    │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Root Application (App-of-Apps Pattern)              │  │
│  └──────────────────────────────────────────────────────┘  │
│                          │                                   │
│        ┌─────────────────┼─────────────────┐                │
│        ▼                 ▼                 ▼                │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐            │
│  │  Infra   │    │ Platform │    │ Business │            │
│  │  Apps    │    │   Apps   │    │   Apps   │            │
│  └──────────┘    └──────────┘    └──────────┘            │
└─────────────────────────────────────────────────────────────┘
                          │
                          │ Deploy
                          ▼
┌─────────────────────────────────────────────────────────────┐
│              Kubernetes Cluster (Production)                 │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Infrastructure Layer                                 │  │
│  │  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐       │  │
│  │  │  Kong  │ │  Ceph  │ │ Monitor│ │ Vault  │       │  │
│  │  └────────┘ └────────┘ └────────┘ └────────┘       │  │
│  │  ┌────────┐ ┌────────┐                             │  │
│  │  │Cloudflr│ │  ESO   │                             │  │
│  │  └────────┘ └────────┘                             │  │
│  └──────────────────────────────────────────────────────┘  │
│                          │                                   │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Application Layer                                    │  │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐            │  │
│  │  │Store API │ │ Payment  │ │   ...    │            │  │
│  │  └──────────┘ └──────────┘ └──────────┘            │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Component Details

### Infrastructure Components

#### Kong Gateway
- **Purpose**: API Gateway and Ingress Controller
- **Deployment**: Helm chart from `charts.konghq.com`
- **Nodes**: Dedicated nodes with `node.kong.gateway: "true"`
- **Replicas**: 3 (HA)
- **Storage**: PostgreSQL for configuration

#### Ceph Storage (Rook)
- **Purpose**: Distributed block and object storage
- **Deployment**: Helm chart + CRDs
- **Nodes**: Dedicated nodes with `node.ceph.storage: "true"`
- **Storage Classes**: `rook-ceph-block` (default)

#### Monitoring Stack
- **Components**: Prometheus, Grafana, AlertManager
- **Deployment**: `kube-prometheus-stack` Helm chart
- **Retention**: 30 days
- **Storage**: Ceph-backed PVCs

#### Vault
- **Purpose**: Secrets management
- **Deployment**: HashiCorp Vault Helm chart
- **Mode**: HA with Consul backend
- **Integration**: External Secrets Operator

#### Cloudflare Tunnel
- **Purpose**: Secure ingress to cluster services
- **Deployment**: Raw YAML (no Helm chart)
- **Replicas**: 2

#### External Secrets Operator
- **Purpose**: Sync secrets from external secret managers
- **Backends**: Vault, AWS Secrets Manager, etc.
- **Deployment**: Helm chart

### Application Layer

#### Business Applications
- Deployed via Helm charts
- Managed by ArgoCD
- Auto-scaling enabled
- Resource limits configured

#### Platform Applications
- Platform-level services
- Shared infrastructure components
- Cross-cutting concerns

## Data Flow

1. **Git Push** → Changes committed to repository
2. **ArgoCD Detection** → ArgoCD polls repository for changes
3. **Sync** → ArgoCD syncs applications automatically
4. **Helm Render** → Helm renders charts with values
5. **Kubernetes Apply** → Resources applied to cluster
6. **Health Check** → ArgoCD monitors application health

## Node Architecture

```
┌─────────────────────────────────────────────────────────┐
│  Control Plane Nodes                                    │
│  - etcd, kube-apiserver, kube-controller-manager       │
│  - kube-scheduler                                       │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  Kong Gateway Nodes (3)                                 │
│  - Label: node.kong.gateway: "true"                    │
│  - Taint: NoSchedule                                    │
│  - Workload: Kong Gateway pods only                     │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  Ceph Storage Nodes (3+)                                │
│  - Label: node.ceph.storage: "true"                     │
│  - Taint: NoSchedule                                    │
│  - Workload: Ceph OSD, MON, MGR                         │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  Worker Nodes (3+)                                      │
│  - Label: node.role: "worker"                           │
│  - Workload: All other applications                     │
└─────────────────────────────────────────────────────────┘
```

## Security Model

1. **Secrets Management**
   - External Secrets Operator syncs from Vault
   - No secrets in Git repository
   - Automatic rotation support

2. **Network Security**
   - Kong Gateway as single ingress point
   - Cloudflare Tunnel for external access
   - Network policies (to be configured)

3. **RBAC**
   - ArgoCD manages permissions
   - Service accounts with least privilege
   - Namespace isolation

4. **Pod Security**
   - Security contexts defined
   - Non-root containers
   - Read-only root filesystems (where possible)

## High Availability

- **Kong**: 3 replicas across nodes
- **Prometheus**: 2 replicas
- **AlertManager**: 2 replicas
- **Vault**: 3 replicas (HA mode)
- **Ceph**: 3 MON nodes minimum
- **External Secrets**: 2 controller replicas

## Storage Strategy

- **Block Storage**: Ceph RBD for databases, stateful apps
- **Object Storage**: Ceph RGW (optional)
- **File Storage**: CephFS (optional)
- **Default StorageClass**: `rook-ceph-block`

## Monitoring & Observability

- **Metrics**: Prometheus scrapes all components
- **Dashboards**: Grafana with pre-configured dashboards
- **Alerts**: AlertManager with default rule sets
- **Logs**: (To be configured - consider Loki)

## Backup Strategy

- **ArgoCD**: Git repository is source of truth
- **Application Data**: Ceph snapshots
- **Secrets**: Vault replication
- **Configuration**: Git version control

## Disaster Recovery

1. **Git Repository**: Primary backup (source of truth)
2. **Ceph**: Replication across nodes
3. **Vault**: HA with Consul backend
4. **ArgoCD**: Can be re-bootstrapped from Git

## Scaling Strategy

- **Horizontal Pod Autoscaling**: Enabled for applications
- **Cluster Autoscaling**: (To be configured)
- **Storage**: Ceph scales with additional OSD nodes
- **Ingress**: Kong scales horizontally

## Future Enhancements

- [ ] Multi-cluster support (staging/test)
- [ ] Service Mesh (Istio/Linkerd)
- [ ] CI/CD integration (GitHub Actions/GitLab CI)
- [ ] Cost optimization (Karpenter)
- [ ] Advanced monitoring (Loki, Tempo)
- [ ] Backup automation (Velero)
- [ ] Security scanning (Falco, Trivy)

