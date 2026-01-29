#!/bin/bash

# Detect OS/Environment
OS_TYPE="$(uname -s)"
IS_WSL=false
if [ "$OS_TYPE" == "Linux" ] && grep -qi "Microsoft" /proc/version; then
    IS_WSL=true
fi

echo "--- Detecting Environment ---"
echo "OS: $OS_TYPE"
[[ "$IS_WSL" == true ]] && echo "Environment: WSL2 (Windows)"

# ---------------------------------------------------------
# 1. INSTALL PODMAN
# ---------------------------------------------------------
if [[ "$OS_TYPE" == "Darwin" ]]; then
    echo "Checking for Podman..."
    if ! command -v podman &> /dev/null; then
        echo "Podman not found. Installing via Homebrew..."
        brew install podman
        echo "Initializing Podman machine..."
        podman machine init
        podman machine start
    fi
else
    echo "Installing Podman for Linux/WSL2..."
    sudo apt-get update
    sudo apt-get install -y podman
fi

# ---------------------------------------------------------
# 2. NVIDIA TOOLKIT & CDI (THE GPU BRIDGE)
# ---------------------------------------------------------
if [[ "$OS_TYPE" == "Darwin" ]]; then
    echo "---------------------------------------------------------"
    echo "NOTICE: macOS detected."
    echo "CUDA is not supported in Podman on macOS."
    echo "Building will work, but it will run in CPU-only mode."
    echo "---------------------------------------------------------"
else
    echo "Checking for NVIDIA GPU..."
    if lspci | grep -qi nvidia || (command -v nvidia-smi &> /dev/null); then
        echo "NVIDIA GPU detected. Setting up NVIDIA Container Toolkit..."
        
        # Add Repository if not present
        curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
        curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
            sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
            sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
        
        sudo apt-get update
        sudo apt-get install -y nvidia-container-toolkit

        # CRITICAL FOR PODMAN: Generate CDI (Container Device Interface) specification
        # This allows Podman to see the GPU without a root daemon
        sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
        
        echo "NVIDIA Toolkit and CDI spec generated successfully."
    else
        echo "No NVIDIA GPU found. Skipping CUDA toolkit installation."
    fi
fi

echo "--- Setup Complete ---"
echo "To run your C++/CUDA container with GPU access, use:"
echo "podman run --rm --device nvidia.com/gpu=all <your-image-name> nvidia-smi"
