#!/bin/bash

# Script to create an Azure Container Registry (ACR) authentication secret in Kubernetes

echo "===== Creating ACR Authentication Secret ====="
echo ""

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
  echo "❌ kubectl not found. Please install it first."
  exit 1
fi

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
  echo "❌ Azure CLI not found. Please install it first."
  exit 1
fi

# Check if logged in to Azure
echo "Checking Azure login status..."
if ! az account show &> /dev/null; then
  echo "You need to log in to Azure first:"
  az login
else
  echo "✅ Already logged in to Azure"
fi

# Set variables
REGISTRY=${1:-"inspiraregistry"}
SECRET_NAME=${2:-"acr-auth"}
NAMESPACE=${3:-"default"}

echo "Registry: $REGISTRY"
echo "Secret Name: $SECRET_NAME"
echo "Namespace: $NAMESPACE"

# Get ACR credentials
echo "Getting ACR credentials..."
ACR_USERNAME=$(az acr credential show -n $REGISTRY --query "username" -o tsv)
ACR_PASSWORD=$(az acr credential show -n $REGISTRY --query "passwords[0].value" -o tsv)

if [ -z "$ACR_USERNAME" ] || [ -z "$ACR_PASSWORD" ]; then
  echo "❌ Failed to get ACR credentials. Make sure the registry exists and you have access to it."
  exit 1
fi

# Create Kubernetes secret
echo "Creating Kubernetes secret..."
kubectl create secret docker-registry $SECRET_NAME \
  --docker-server=$REGISTRY.azurecr.io \
  --docker-username=$ACR_USERNAME \
  --docker-password=$ACR_PASSWORD \
  --namespace=$NAMESPACE \
  --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "===== ACR Authentication Secret Created ====="
echo ""
echo "You can now use this secret in your Kubernetes deployments by adding:"
echo ""
echo "spec:"
echo "  template:"
echo "    spec:"
echo "      imagePullSecrets:"
echo "      - name: $SECRET_NAME" 