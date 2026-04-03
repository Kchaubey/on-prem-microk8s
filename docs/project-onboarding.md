# Project Onboarding Guide

Use this when onboarding a new application to this blue-green Helm setup.

## 1) Create Your App Values File

Start from the sample override file:

```bash
cp bluegreen-deployment/values/values-sample.yaml \
   bluegreen-deployment/values/values-<your-app>.yaml
```

Update at minimum:

- `projectName`
- `projectNamespace`
- `image.repository`
- `service.port`
- `service.targetPort`
- `ingress.hosts` and `ingress.tls`
- health probes under `healthCheck`

## 2) Choose CI Platform

- GitLab CI: use `Projects-k8s-pipeline/_template/k8.yml`
- GitHub Actions: use `Projects-k8s-pipeline/_template/github-actions-bluegreen.yml`

Detailed steps: [`ci-platform-guide.md`](./ci-platform-guide.md)

## 3) Validate Before Merge

```bash
helm lint bluegreen-deployment \
  -f bluegreen-deployment/values/values-<your-app>.yaml \
  --set-string image.tag=test

helm template <release-name> bluegreen-deployment \
  -f bluegreen-deployment/values/values-<your-app>.yaml \
  --set-string image.tag=test >/tmp/<release-name>.yaml

kubectl apply --dry-run=client -f /tmp/<release-name>.yaml
```

## 4) Recommended Rollout Flow

1. Deploy candidate image to green while blue is live.
2. Smoke test `green-service` endpoint.
3. Switch active traffic to green.
4. Verify live endpoint.
5. Roll back to blue if verification fails.

## 5) Backend-Safe Option (DB Sensitive)

```yaml
blueGreen:
  scaleDownInactive: true
  inactiveReplicaCount: 0

deploymentStrategy:
  green:
    type: Recreate
```

## 6) Onboarding Checklist

- [ ] Values file created from sample and reviewed
- [ ] CI template chosen (GitLab or GitHub)
- [ ] CI secrets/variables configured
- [ ] Probes and service ports validated
- [ ] First deploy, promote, and rollback tested
