#!/bin/bash
set -e

PROJECT_NAME=$1
HELM_CHART_REPO=$2
KUBE_NAMESPACE=${3:-production}
IMAGE_TAG=${4:-green}
BLUE_TAG=${5:-$IMAGE_TAG}
GREEN_TAG=${6:-$IMAGE_TAG}
ACTIVE_VERSION=${7:-blue}
VALUES_FILE="values/${PROJECT_NAME}.yaml"

echo "Deploying $PROJECT_NAME to Kubernetes using Helm..."
echo "Helm Chart Repo: $HELM_CHART_REPO"
echo "Namespace: $KUBE_NAMESPACE"
echo "Values File: $VALUES_FILE"
echo "Image Tag: $IMAGE_TAG"
echo "Blue Tag: $BLUE_TAG"
echo "Green Tag: $GREEN_TAG"
echo "Active Version: $ACTIVE_VERSION"

if [ -z "$KUBECONFIG" ]; then
    echo "Error: KUBECONFIG environment variable not set"
    exit 1
fi

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

helm upgrade --install "${PROJECT_NAME}" \
    helm-repo/bluegreen-deployment \
    -n "$KUBE_NAMESPACE" \
    --values "helm-repo/${VALUES_FILE}" \
    --set "image.tag=${IMAGE_TAG}" \
    --set "image.blueTag=${BLUE_TAG}" \
    --set "image.greenTag=${GREEN_TAG}" \
    --set "blueGreen.activeVersion=${ACTIVE_VERSION}" \
    --wait \
    --timeout 5m

echo "Helm deployment completed"
