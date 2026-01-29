#!/bin/bash
set -e

PROJECT_VERSION=$(git describe --tags --always || echo "0.1.0")
IMAGE_NAME="oxdna-dev"
OS_TYPE="$(uname -s)"

has_gpu() {
    if command -v nvidia-smi &> /dev/null; then return 0; fi
    if lspci | grep -qi nvidia; then return 0; fi
    return 1
}

if [[ "$OS_TYPE" == "Darwin" ]]; then
    FLAVOR="cpu"
    BASE="ubuntu:22.04"
elif has_gpu; then
    FLAVOR="cuda"
    BASE="nvidia/cuda:12.3.1-devel-ubuntu22.04"
else
    FLAVOR="cpu"
    BASE="ubuntu:22.04"
fi

FULL_TAG="${IMAGE_NAME}:${PROJECT_VERSION}-${FLAVOR}"

echo "--- Building Env: ${FULL_TAG} ---"

podman build \
    --build-arg BASE_IMAGE="${BASE}" \
    -t "${FULL_TAG}" \
    -t "${IMAGE_NAME}:latest-${FLAVOR}" $(cd "$(dirname "$0")" && pwd)

echo "--- Build Complete ---"
echo "Tagged as: ${FULL_TAG}"
