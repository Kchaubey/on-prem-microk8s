#!/bin/bash
set -euo pipefail

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <project-name> <helm-chart-repo> [namespace] [target-version] [image-tag] [blue-tag] [green-tag] [helm-timeout]"
    exit 1
fi

PROJECT_NAME=$1
HELM_CHART_REPO=$2
KUBE_NAMESPACE=${3:-production}
TARGET_VERSION=${4:-green}
IMAGE_TAG=${5:-}
BLUE_TAG=${6:-}
GREEN_TAG=${7:-}
HELM_TIMEOUT=${8:-${HELM_TIMEOUT:-10m}}
CLONE_DIR="helm-repo"
CHART_PATH=""
CHART_CANDIDATES=(
    "${CLONE_DIR}/bluegreen-deployment"
    "${CLONE_DIR}"
)

echo "Switching traffic to ${TARGET_VERSION} deployment..."
echo "Helm Timeout: $HELM_TIMEOUT"
echo "Reusing current release values to avoid image tag resets"

if [ -z "${KUBECONFIG:-}" ]; then
    echo "Error: KUBECONFIG environment variable not set"
    exit 1
fi

if [ "$TARGET_VERSION" != "blue" ] && [ "$TARGET_VERSION" != "green" ]; then
    echo "Error: TARGET_VERSION must be 'blue' or 'green', got '$TARGET_VERSION'"
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

echo "Using Chart Path: $CHART_PATH"

HELM_ARGS=(
    upgrade "${PROJECT_NAME}"
    "${CHART_PATH}"
    -n "$KUBE_NAMESPACE"
    --set-string "blueGreen.activeVersion=${TARGET_VERSION}"
    --reuse-values
    --wait
    --timeout "$HELM_TIMEOUT"
)

if [ -n "$IMAGE_TAG" ]; then
    HELM_ARGS+=(--set-string "image.tag=${IMAGE_TAG}")
fi

if [ -n "$BLUE_TAG" ]; then
    HELM_ARGS+=(--set-string "image.blueTag=${BLUE_TAG}")
fi

if [ -n "$GREEN_TAG" ]; then
    HELM_ARGS+=(--set-string "image.greenTag=${GREEN_TAG}")
fi

helm "${HELM_ARGS[@]}"

echo "Traffic switched successfully"
kubectl get services -n "$KUBE_NAMESPACE" | grep "$PROJECT_NAME"
