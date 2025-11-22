# Applications

This directory contains Helm values files for all business and platform applications.

## Structure

```
apps/
├── business/          # Business applications
│   ├── store-api/
│   │   └── values.yaml
│   └── payment-service/
│       └── values.yaml
└── platform/          # Platform-level applications
    └── ...
```

## Adding New Applications

1. Create a new directory under `apps/business/` or `apps/platform/`
2. Add your `values.yaml` file
3. Create an ArgoCD Application manifest in `clusters/prod/apps/business/` or `clusters/prod/apps/platform/`
4. Commit and push - ArgoCD will automatically deploy

## Example Application Structure

Each application should have:
- `values.yaml` - Helm values for the application
- Optional: `README.md` - Application-specific documentation

## ArgoCD Application Pattern

Applications are managed via ArgoCD Application CRs in `clusters/prod/apps/`. The root application uses directory recursion to discover all applications automatically.

