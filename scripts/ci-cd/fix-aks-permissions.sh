#!/bin/bash

# Script to fix AKS permissions issues in the CI/CD pipeline

echo "===== Fixing AKS Permissions ====="

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "Azure CLI not found. Installing..."
    curl -sL https://aka.ms/InstallAzureCLIDeb | bash
    echo "Azure CLI installed successfully."
else
    echo "Azure CLI already installed."
fi

# Login to Azure if needed
echo "Checking Azure login status..."
if ! az account show &> /dev/null; then
    echo "Not logged in to Azure. Please login:"
    az login --use-device-code
else
    echo "Already logged in to Azure."
fi

# Set subscription if provided
if [ -n "$1" ]; then
    echo "Setting subscription to $1..."
    az account set --subscription "$1"
fi

# Get current user/service principal ID
CURRENT_ID=$(az ad signed-in-user show --query id -o tsv 2>/dev/null || az account show --query user.name -o tsv)
echo "Current user/service principal ID: $CURRENT_ID"

# Set variables
RESOURCE_GROUP=${2:-"inspira-resources"}
AKS_CLUSTER=${3:-"inspira-cluster"}

echo "Resource Group: $RESOURCE_GROUP"
echo "AKS Cluster: $AKS_CLUSTER"

# Check if resource group exists
if ! az group show --name "$RESOURCE_GROUP" &> /dev/null; then
    echo "Resource group $RESOURCE_GROUP does not exist. Creating..."
    LOCATION=${4:-"eastus"}
    az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
    echo "Resource group created."
fi

# Check if AKS cluster exists
if ! az aks show --resource-group "$RESOURCE_GROUP" --name "$AKS_CLUSTER" &> /dev/null; then
    echo "AKS cluster $AKS_CLUSTER does not exist in resource group $RESOURCE_GROUP."
    echo "Please create the AKS cluster first or provide correct names."
    exit 1
fi

# Add the current user as a cluster admin
echo "Adding current user/service principal as AKS cluster admin..."
az role assignment create \
    --assignee "$CURRENT_ID" \
    --role "Azure Kubernetes Service Cluster Admin Role" \
    --scope "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.ContainerService/managedClusters/$AKS_CLUSTER"

# Add the current user as a cluster user
echo "Adding current user/service principal as AKS cluster user..."
az role assignment create \
    --assignee "$CURRENT_ID" \
    --role "Azure Kubernetes Service Cluster User Role" \
    --scope "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.ContainerService/managedClusters/$AKS_CLUSTER"

# Add the current user as a contributor to the resource group
echo "Adding current user/service principal as resource group contributor..."
az role assignment create \
    --assignee "$CURRENT_ID" \
    --role "Contributor" \
    --resource-group "$RESOURCE_GROUP"

# Get AKS credentials
echo "Getting AKS credentials..."
az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$AKS_CLUSTER" --overwrite-existing

echo "===== AKS Permissions Fixed ====="
echo ""
echo "You should now have the necessary permissions to access the AKS cluster."
echo "If you're using this in a CI/CD pipeline, make sure to update the Azure credentials secret."
echo ""
echo "To update GitHub Actions Azure credentials, run:"
echo "az ad sp create-for-rbac --name \"inspira-github-actions\" --role contributor \\"
echo "  --scopes /subscriptions/\$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP \\"
echo "  --sdk-auth"
echo ""
echo "Then add the output JSON as a GitHub secret named AZURE_CREDENTIALS" 