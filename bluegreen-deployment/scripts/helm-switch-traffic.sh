#!/bin/bash
set -euo pipefail

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <project-name> <helm-chart-repo> [namespace] [target-version] [image-tag] [blue-tag] [green-tag] [helm-timeout] [warmup-replicas]"
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
WARMUP_REPLICAS=${9:-1}
CLONE_DIR="helm-repo"
CHART_PATH=""
CHART_CANDIDATES=(
    "${CLONE_DIR}/bluegreen-deployment"
    "${CLONE_DIR}"
)

echo "Switching traffic to ${TARGET_VERSION} deployment..."
echo "Helm Timeout: $HELM_TIMEOUT"
echo "Warmup Replicas: $WARMUP_REPLICAS"
echo "Reusing current release values to avoid image tag resets"

if [ -z "${KUBECONFIG:-}" ]; then
    echo "Error: KUBECONFIG environment variable not set"
    exit 1
fi

if [ "$TARGET_VERSION" != "blue" ] && [ "$TARGET_VERSION" != "green" ]; then
    echo "Error: TARGET_VERSION must be 'blue' or 'green', got '$TARGET_VERSION'"
    exit 1
fi

if ! [[ "$WARMUP_REPLICAS" =~ ^[0-9]+$ ]]; then
    echo "Error: WARMUP_REPLICAS must be a non-negative integer, got '$WARMUP_REPLICAS'"
    exit 1
fi

TARGET_DEPLOYMENT="${PROJECT_NAME}-${TARGET_VERSION}"
if kubectl get deployment "$TARGET_DEPLOYMENT" -n "$KUBE_NAMESPACE" >/dev/null 2>&1; then
    if [ "$WARMUP_REPLICAS" -gt 0 ]; then
        echo "Warming up ${TARGET_DEPLOYMENT} with ${WARMUP_REPLICAS} replica(s) before switching traffic..."
        kubectl scale deployment "$TARGET_DEPLOYMENT" -n "$KUBE_NAMESPACE" --replicas="$WARMUP_REPLICAS"
        kubectl rollout status deployment/"$TARGET_DEPLOYMENT" -n "$KUBE_NAMESPACE" --timeout="$HELM_TIMEOUT"
    fi
else
    echo "Warning: deployment ${TARGET_DEPLOYMENT} not found in namespace ${KUBE_NAMESPACE}; skipping warmup"
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
    --atomic
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
