# Project K8s Pipelines

Each subfolder contains a standalone `k8.yml` GitLab pipeline file for one values file from `bluegreen-deployment/values/`.

Usage:
1. Open the matching subfolder.
2. Copy `k8.yml` into your project repository as `.gitlab-ci.yml` (or include it).
3. Adjust `rules`, `tags`, `HELM_CHART_REPO`, and health-check path if your project differs.
