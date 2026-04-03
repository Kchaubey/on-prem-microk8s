# Pipeline Templates

This folder contains only sample CI/CD templates for blue-green Kubernetes deployments.

## Available Templates

- `Projects-k8s-pipeline/_template/k8.yml` (GitLab CI)
- `Projects-k8s-pipeline/_template/github-actions-bluegreen.yml` (GitHub Actions)

## What To Use

- If your project is on GitLab: use `k8.yml`
- If your project is on GitHub: use `github-actions-bluegreen.yml`

Full platform guide: [`../docs/ci-platform-guide.md`](../docs/ci-platform-guide.md)

## Notes

- Templates are intentionally generic and safe for public sharing.
- Update project values, namespace, chart repo URL, and health path before first run.
