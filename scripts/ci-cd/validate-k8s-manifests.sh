#!/bin/bash

# Script to install kubeval and validate Kubernetes manifests

echo "===== Kubernetes Manifest Validation ====="
echo ""

# Check if kubeval is installed
if ! command -v kubeval &> /dev/null; then
  echo "kubeval not found. Installing kubeval..."
  
  # Check OS
  OS=$(uname -s | tr '[:upper:]' '[:lower:]')
  
  if [ "$OS" == "darwin" ]; then
    # macOS - download binary directly
    echo "Downloading kubeval binary for macOS..."
    curl -L -o kubeval.tar.gz https://github.com/instrumenta/kubeval/releases/latest/download/kubeval-darwin-amd64.tar.gz
    tar xf kubeval.tar.gz
    chmod +x kubeval
    mv kubeval /usr/local/bin/ 2>/dev/null || sudo mv kubeval /usr/local/bin/ || mv kubeval .
    rm -f kubeval.tar.gz
    echo "kubeval binary downloaded. If it wasn't moved to /usr/local/bin, it's in the current directory."
  elif [ "$OS" == "linux" ]; then
    # Linux - download binary
    echo "Downloading kubeval binary for Linux..."
    curl -L -o kubeval.tar.gz https://github.com/instrumenta/kubeval/releases/latest/download/kubeval-linux-amd64.tar.gz
    tar xf kubeval.tar.gz
    chmod +x kubeval
    mv kubeval /usr/local/bin/ 2>/dev/null || sudo mv kubeval /usr/local/bin/ || mv kubeval .
    rm -f kubeval.tar.gz
    echo "kubeval binary downloaded. If it wasn't moved to /usr/local/bin, it's in the current directory."
  else
    echo "Unsupported OS: $OS"
    exit 1
  fi
else
  echo "✅ kubeval is already installed"
fi

# Check if kubeval is now in PATH
if ! command -v kubeval &> /dev/null; then
  if [ -f "./kubeval" ]; then
    echo "Using kubeval from current directory"
    KUBEVAL="./kubeval"
  else
    echo "❌ Failed to install kubeval"
    exit 1
  fi
else
  KUBEVAL="kubeval"
fi

echo ""
echo "===== Validating Kubernetes Manifests ====="
echo ""

# Check if k8s-azure directory exists
if [ -d "k8s-azure" ]; then
  echo "Validating manifests in k8s-azure directory..."
  $KUBEVAL --ignore-missing-schemas k8s-azure/*.yaml
  if [ $? -eq 0 ]; then
    echo "✅ All manifests in k8s-azure directory are valid"
  else
    echo "❌ Some manifests in k8s-azure directory are invalid"
  fi
else
  echo "k8s-azure directory not found. Creating it..."
  mkdir -p k8s-azure
  
  # Generate manifests using the prepare script if available
  if [ -f "scripts/ci-cd/prepare-k8s-manifests.sh" ]; then
    echo "Generating manifests using prepare-k8s-manifests.sh..."
    chmod +x scripts/ci-cd/prepare-k8s-manifests.sh
    ./scripts/ci-cd/prepare-k8s-manifests.sh
    
    echo "Validating generated manifests..."
    $KUBEVAL --ignore-missing-schemas k8s-azure/*.yaml
    if [ $? -eq 0 ]; then
      echo "✅ All generated manifests are valid"
    else
      echo "❌ Some generated manifests are invalid"
    fi
  else
    echo "❌ Manifest preparation script not found"
  fi
fi

# Check if k8s/base directory exists
if [ -d "k8s/base" ]; then
  echo ""
  echo "Validating manifests in k8s/base directory..."
  $KUBEVAL --ignore-missing-schemas k8s/base/*.yaml
  if [ $? -eq 0 ]; then
    echo "✅ All manifests in k8s/base directory are valid"
  else
    echo "❌ Some manifests in k8s/base directory are invalid"
  fi
else
  echo ""
  echo "k8s/base directory not found. Skipping validation."
fi

echo ""
echo "===== Validation Complete ====="
echo ""
echo "For more information on kubeval, see:"
echo "https://github.com/instrumenta/kubeval"
echo ""
echo "To fix any validation errors, refer to:"
echo "docs/ci-cd/KUBERNETES-MANIFESTS-GUIDE.md" 