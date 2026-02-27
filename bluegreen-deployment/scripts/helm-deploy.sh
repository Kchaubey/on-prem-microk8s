#!/bin/bash
set -euo pipefail

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <project-name> <helm-chart-repo> [namespace] [image-tag] [blue-tag] [green-tag] [active-version] [helm-timeout]"
    exit 1
fi

PROJECT_NAME=$1
HELM_CHART_REPO=$2
KUBE_NAMESPACE=${3:-production}
IMAGE_TAG=${4:-green}
BLUE_TAG=${5:-$IMAGE_TAG}
GREEN_TAG=${6:-$IMAGE_TAG}
ACTIVE_VERSION=${7:-blue}
HELM_TIMEOUT=${8:-${HELM_TIMEOUT:-10m}}
CLONE_DIR="helm-repo"
CHART_PATH=""
VALUES_FILE=""
CHART_CANDIDATES=(
    "${CLONE_DIR}/bluegreen-deployment"
    "${CLONE_DIR}"
)
VALUES_CANDIDATES=(
    "bluegreen-deployment/values/${PROJECT_NAME}.yaml"
    "bluegreen-deployment/values/values-${PROJECT_NAME}.yaml"
    "values/${PROJECT_NAME}.yaml"
    "values/values-${PROJECT_NAME}.yaml"
)

echo "Deploying $PROJECT_NAME to Kubernetes using Helm..."
echo "Helm Chart Repo: $HELM_CHART_REPO"
echo "Namespace: $KUBE_NAMESPACE"
echo "Image Tag: $IMAGE_TAG"
echo "Blue Tag: $BLUE_TAG"
echo "Green Tag: $GREEN_TAG"
echo "Active Version: $ACTIVE_VERSION"
echo "Helm Timeout: $HELM_TIMEOUT"

if [ -z "$KUBECONFIG" ]; then
    echo "Error: KUBECONFIG environment variable not set"
    exit 1
fi

if [ "$ACTIVE_VERSION" != "blue" ] && [ "$ACTIVE_VERSION" != "green" ]; then
    echo "Error: ACTIVE_VERSION must be 'blue' or 'green', got '$ACTIVE_VERSION'"
    exit 1
fi

rm -rf "$CLONE_DIR"
git clone "$HELM_CHART_REPO" "$CLONE_DIR"

for candidate in "${CHART_CANDIDATES[@]}"; do
    if [ -f "${candidate}/Chart.yaml" ]; then
        CHART_PATH="${candidate}"
        break
    fi
done

if [ -z "$CHART_PATH" ]; then
    echo "Error: Helm chart not found in cloned repo '$HELM_CHART_REPO'"
    exit 1
fi

for candidate in "${VALUES_CANDIDATES[@]}"; do
    if [ -f "${CLONE_DIR}/${candidate}" ]; then
        VALUES_FILE="${candidate}"
        break
    fi
done

if [ -z "$VALUES_FILE" ]; then
    echo "Error: values file not found for project '$PROJECT_NAME'"
    exit 1
fi

echo "Using Values File: $VALUES_FILE"
echo "Using Chart Path: $CHART_PATH"

helm upgrade --install "${PROJECT_NAME}" \
    "${CHART_PATH}" \
    -n "$KUBE_NAMESPACE" \
    --values "${CLONE_DIR}/${VALUES_FILE}" \
    --set-string "image.tag=${IMAGE_TAG}" \
    --set-string "image.blueTag=${BLUE_TAG}" \
    --set-string "image.greenTag=${GREEN_TAG}" \
    --set-string "blueGreen.activeVersion=${ACTIVE_VERSION}" \
    --wait \
    --timeout "$HELM_TIMEOUT"

echo "Helm deployment completed"
