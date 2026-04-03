# Deployment Runbook

Day-2 operations for blue-green deployment using this chart.

## Preconditions

- `kubectl` and `helm` are installed
- kubeconfig points to target cluster
- namespace exists
- image pull secret exists in namespace
- values file exists (`values-<your-app>.yaml`)

## Deploy Candidate to Green (Keep Blue Live)

```bash
RELEASE_NAME="my-app"
NAMESPACE="production"
VALUES_FILE="bluegreen-deployment/values/values-<your-app>.yaml"
CANDIDATE_TAG="<new-image-tag>"
CURRENT_BLUE_TAG="<current-live-tag>"

helm upgrade --install "$RELEASE_NAME" bluegreen-deployment \
  -n "$NAMESPACE" \
  --create-namespace \
  -f "$VALUES_FILE" \
  --set-string image.tag="$CANDIDATE_TAG" \
  --set-string image.blueTag="$CURRENT_BLUE_TAG" \
  --set-string image.greenTag="$CANDIDATE_TAG" \
  --set-string blueGreen.activeVersion=blue \
  --atomic --wait --timeout 10m
```

## Smoke Test Green

```bash
kubectl port-forward -n production svc/my-app-green-service 18005:8080
curl -fsS http://127.0.0.1:18005/health
```

## Promote Traffic to Green

```bash
helm upgrade my-app bluegreen-deployment \
  -n production \
  --reuse-values \
  --set-string blueGreen.activeVersion=green \
  --atomic --wait --timeout 10m
```

## Verify Live Service

```bash
kubectl port-forward -n production svc/my-app-service 18006:8080
curl -fsS http://127.0.0.1:18006/health
```

## Roll Back to Blue

```bash
helm upgrade my-app bluegreen-deployment \
  -n production \
  --reuse-values \
  --set-string blueGreen.activeVersion=blue \
  --atomic --wait --timeout 10m
```

## Helm Revision Rollback

```bash
helm history my-app -n production
helm rollback my-app <revision> -n production --wait --timeout 10m
```

## Scripted Helpers

```bash
./bluegreen-deployment/scripts/helm-deploy.sh \
  my-app <helm-chart-repo-url> production <image-tag> <blue-tag> <green-tag> blue 10m

./bluegreen-deployment/scripts/helm-switch-traffic.sh \
  my-app <helm-chart-repo-url> production green "" "" "" 10m 1
```

## Incident Quick Checks

```bash
kubectl get deploy,po,svc,hpa -n production -l app=my-app
kubectl describe deploy my-app-green -n production
kubectl logs deploy/my-app-green -n production --tail=200
helm get values my-app -n production -o yaml
```
