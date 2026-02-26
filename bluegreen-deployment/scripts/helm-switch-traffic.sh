#!/bin/bash
set -e

PROJECT_NAME=$1
HELM_CHART_REPO=$2
KUBE_NAMESPACE=${3:-production}
TARGET_VERSION=${4:-green}
VALUES_FILE="values/${PROJECT_NAME}.yaml"

echo "Switching traffic to ${TARGET_VERSION} deployment..."

git clone "$HELM_CHART_REPO" helm-repo

if [ ! -f "helm-repo/${VALUES_FILE}" ]; then
    ALT_VALUES_FILE="values/values-${PROJECT_NAME}.yaml"
    if [ -f "helm-repo/${ALT_VALUES_FILE}" ]; then
        VALUES_FILE="${ALT_VALUES_FILE}"
        echo "Using Values File: $VALUES_FILE"
    else
        echo "Error: values file not found for project '$PROJECT_NAME'"
        exit 1
    fi
fi

helm upgrade "${PROJECT_NAME}" \
    helm-repo/bluegreen-deployment \
    -n "$KUBE_NAMESPACE" \
    --values "helm-repo/${VALUES_FILE}" \
    --set "blueGreen.activeVersion=${TARGET_VERSION}" \
    --wait \
    --timeout 2m

echo "Traffic switched successfully"
kubectl get services -n "$KUBE_NAMESPACE" | grep "$PROJECT_NAME"
