# Helm Charts - Blue-Green Deployment

This repository contains Helm charts for blue-green deployment strategy on MicroK8s.

## Structure

- `bluegreen-deployment/` - Main Helm chart for blue-green deployments
  - `templates/` - Kubernetes manifest templates
  - `scripts/` - Deployment helper scripts
  - `values/` - Project-specific values files

## Quick Start

```bash
# Deploy a project
helm upgrade --install doctor-web bluegreen-deployment \
  -n production \
  --create-namespace \
  -f bluegreen-deployment/values/values-doctor-web.yaml

# Switch traffic from blue to green
helm upgrade doctor-web bluegreen-deployment \
  -n production \
  --reuse-values \
  --set blueGreen.activeVersion=green
```

## Projects Included

### Health Gini Group
- doctor-web
- admin-web
- patient-web
- super-admin-web
- centralized-backend
- webapp-poc

### Neuraiq Group
- nurovision-backend
- nurovision-frontend
- neo-app

### Voxify Group
- vox-ai
- vox-backend
- vox-frontend
- vox-mobile

## Documentation

See individual project repositories for deployment instructions.
