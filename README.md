# Kubernetes Blue-Green Reference Repo (Public-Safe)

This repository is a generic reference for deploying applications to Kubernetes using:

- Helm chart (`bluegreen-deployment`)
- Blue-Green rollout strategy
- CI/CD templates for both GitLab CI and GitHub Actions

All company-specific project files were removed. Only sample files are included.

## Repository Structure

```text
.
├── bluegreen-deployment/
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── values/
│   │   └── values-sample.yaml
│   ├── templates/
│   └── scripts/
├── Projects-k8s-pipeline/
│   ├── _template/
│   │   ├── k8.yml
│   │   └── github-actions-bluegreen.yml
│   └── README.md
└── docs/
    ├── ci-platform-guide.md
    ├── microk8s-cluster-bootstrap.md
    ├── project-onboarding.md
    ├── deployment-runbook.md
    └── troubleshooting.md
```

## CI Platform Choice (Important)

Use the template based on your platform:

- GitLab CI: copy `Projects-k8s-pipeline/_template/k8.yml` to your app repo as `.gitlab-ci.yml`
- GitHub Actions: copy `Projects-k8s-pipeline/_template/github-actions-bluegreen.yml` to your app repo as `.github/workflows/bluegreen-k8s.yml`

Detailed guide: [`docs/ci-platform-guide.md`](docs/ci-platform-guide.md)

## Quick Start

1. Copy sample values file:

```bash
cp bluegreen-deployment/values/values-sample.yaml bluegreen-deployment/values/values-<your-app>.yaml
```

2. Update app-specific fields in your copied file:

- `projectName`
- `projectNamespace`
- `image.repository`
- `service.port` and `service.targetPort`
- `ingress.hosts` and `ingress.tls`

3. Validate chart rendering:

```bash
helm lint bluegreen-deployment -f bluegreen-deployment/values/values-<your-app>.yaml --set-string image.tag=test
helm template <release-name> bluegreen-deployment -f bluegreen-deployment/values/values-<your-app>.yaml --set-string image.tag=test >/tmp/<release-name>.yaml
```

4. Deploy and switch traffic:

```bash
helm upgrade --install <release-name> bluegreen-deployment \
  -n <namespace> \
  --create-namespace \
  -f bluegreen-deployment/values/values-<your-app>.yaml \
  --set-string image.tag=<new-tag> \
  --set-string blueGreen.activeVersion=blue

helm upgrade <release-name> bluegreen-deployment \
  -n <namespace> \
  --reuse-values \
  --set-string blueGreen.activeVersion=green
```

## Documentation

- CI platform selection: [`docs/ci-platform-guide.md`](docs/ci-platform-guide.md)
- Cluster bootstrap: [`docs/microk8s-cluster-bootstrap.md`](docs/microk8s-cluster-bootstrap.md)
- Project onboarding: [`docs/project-onboarding.md`](docs/project-onboarding.md)
- Deployment operations: [`docs/deployment-runbook.md`](docs/deployment-runbook.md)
- Expected issues and fixes: [`docs/troubleshooting.md`](docs/troubleshooting.md)
