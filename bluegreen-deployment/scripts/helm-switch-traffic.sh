#!/bin/bash
set -e

PROJECT_NAME=$1
HELM_CHART_REPO=$2
KUBE_NAMESPACE=${3:-production}
VALUES_FILE="values/${PROJECT_NAME}.yaml"

echo "Switching traffic to green deployment..."

git clone "$HELM_CHART_REPO" helm-repo

helm upgrade "${PROJECT_NAME}" \
    helm-repo/bluegreen-deployment \
    -n "$KUBE_NAMESPACE" \
    --values "helm-repo/${VALUES_FILE}" \
    --set image.tag=green \
    --set blueGreen.activeVersion=green \
    --wait \
    --timeout 2m

echo "Traffic switched successfully"
kubectl get services -n "$KUBE_NAMESPACE" | grep "$PROJECT_NAME"
