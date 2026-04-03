# CI Platform Guide: GitLab vs GitHub

Use this quick decision guide to choose the right deployment template.

## If You Use GitLab CI

Use:

- `Projects-k8s-pipeline/_template/k8.yml`

Copy to your application repository:

```bash
cp Projects-k8s-pipeline/_template/k8.yml <app-repo>/.gitlab-ci.yml
```

Required secret variables in GitLab:

- `KUBE_URL`
- `KUBE_CA_CERT`
- `KUBE_TOKEN`
- `Docker_REGISTRY_URL`
- `Docker_REGISTRY_USER`
- `Docker_REGISTRY_PASSWORD`

Main variables to update inside `k8.yml`:

- `PROJECT_NAME`
- `KUBE_NAMESPACE`
- `HELM_CHART_REPO`
- `VALUES_FILE`
- `HEALTH_PATH`

## If You Use GitHub Actions

Use:

- `Projects-k8s-pipeline/_template/github-actions-bluegreen.yml`

Copy to your application repository:

```bash
mkdir -p <app-repo>/.github/workflows
cp Projects-k8s-pipeline/_template/github-actions-bluegreen.yml <app-repo>/.github/workflows/bluegreen-k8s.yml
```

Required repository secrets in GitHub:

- `KUBE_URL`
- `KUBE_CA_CERT`
- `KUBE_TOKEN`
- `Docker_REGISTRY_URL`
- `Docker_REGISTRY_USER`
- `Docker_REGISTRY_PASSWORD`

Required repository variable in GitHub:

- `HELM_CHART_REPO`

Main environment values to update inside workflow:

- `PROJECT_NAME`
- `KUBE_NAMESPACE`
- `VALUES_FILE`
- `HEALTH_PATH`

## Which One Should You Choose?

- Your source repo on GitLab: use the GitLab template.
- Your source repo on GitHub: use the GitHub Actions template.

Both templates implement the same release pattern:

- deploy candidate to green
- smoke test green
- switch live traffic to green
- rollback if live verification fails
