#!/bin/bash
set -e

PROJECT_NAME=$1
HELM_CHART_REPO=$2
KUBE_NAMESPACE=${3:-production}
VALUES_FILE="values/${PROJECT_NAME}.yaml"

echo "Deploying $PROJECT_NAME to Kubernetes using Helm..."
echo "Helm Chart Repo: $HELM_CHART_REPO"
echo "Namespace: $KUBE_NAMESPACE"
echo "Values File: $VALUES_FILE"

if [ -z "$KUBECONFIG" ]; then
    echo "Error: KUBECONFIG environment variable not set"
    exit 1
fi

git clone "$HELM_CHART_REPO" helm-repo

helm upgrade --install "${PROJECT_NAME}" \
    helm-repo/bluegreen-deployment \
    -n "$KUBE_NAMESPACE" \
    --values "helm-repo/${VALUES_FILE}" \
    --set image.tag=green \
    --set blueGreen.activeVersion=blue \
    --wait \
    --timeout 5m

echo "Helm deployment completed"
