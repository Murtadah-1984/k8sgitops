# Kong Gateway

Kong Gateway provides API gateway functionality with ingress control.

## Configuration

- **Node Affinity**: Deploys to nodes with label `node.kong.gateway: "true"`
- **Tolerations**: Tolerates taint `node.kong.gateway: "true":NoSchedule`
- **Replicas**: 3 for high availability
- **Database**: PostgreSQL (configure via External Secrets)

## Prerequisites

1. PostgreSQL database (deploy separately or use managed service)
2. Dedicated nodes labeled with `node.kong.gateway: "true"`
3. External Secrets Operator for database credentials

## Secrets

Database credentials should be managed via External Secrets Operator:
- Secret name: `kong-postgres-credentials`
- Keys: `username`, `password`, `database`

