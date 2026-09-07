#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="${IMAGE_NAME:-mindoc}"
IMAGE_TAG="$(date +%Y%m%d)"
IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"

if ! command -v docker >/dev/null 2>&1; then
    echo "错误：未找到 docker 命令。" >&2
    exit 1
fi

if ! docker buildx version >/dev/null 2>&1; then
    echo "错误：当前 Docker 未安装或未启用 buildx。" >&2
    exit 1
fi

echo "开始构建镜像 ${IMAGE}（linux/amd64）"


IMAGE="service-app:${IMAGE_TAG}" #Special requirement: service-app can be commented out.

docker buildx build \
    --platform linux/amd64 \
    --load \
    --build-arg "TAG=${IMAGE_TAG}" \
    --tag "${IMAGE}" \
    "${SCRIPT_DIR}"



echo "镜像构建完成：${IMAGE}"
