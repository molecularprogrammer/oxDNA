#!/bin/bash
set -e

# --- Configuration ---
# Match these to the tags created by your previous script
PROJECT_VERSION=$(git describe --tags --always || echo "0.1.0")
IMAGE_NAME="oxdna-dev"
OS_TYPE="$(uname -s)"

# 1. Determine which flavor to use
if [[ "$OS_TYPE" == "Darwin" ]]; then
    FLAVOR="cpu"
    CUDA_SETTING="OFF"
else
    # Check for GPU (reuse logic from your setup script)
    if command -v nvidia-smi &> /dev/null || lspci | grep -qi nvidia; then
        FLAVOR="cuda"
        CUDA_SETTING="ON"
    else
        FLAVOR="cpu"
        CUDA_SETTING="OFF"
    fi
fi

FULL_TAG="${IMAGE_NAME}:${PROJECT_VERSION}-${FLAVOR}"

echo "--- Building App using Container: ${FULL_TAG} ---"

# 2. Run the build inside the container
# --rm: Clean up the container after build
# -v: Mount current directory to /workspace
# --userns=keep-id: CRITICAL for Podman to ensure files created in container 
#                  are owned by YOU on the host, not root.
podman run --rm \
    -v "$(pwd):/workspace:Z" \
    --userns=keep-id \
    --workdir /workspace \
    "$FULL_TAG" \
    /bin/bash -c "mkdir -p build && cd build && cmake -DCUDA=${CUDA_SETTING} .. && make -j$(nproc)"

echo "--- Build Finished! ---"
echo "Binaries are located in the ./build directory on your host."
