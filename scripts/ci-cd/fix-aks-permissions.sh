#!/bin/bash

# Script to fix AKS permissions for the service principal

echo "===== AKS Permissions Fix ====="
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
  echo "❌ Azure CLI not found. Please install it first:"
  echo "https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
  exit 1
fi

# Check if user is logged in
echo "Checking Azure login status..."
az account show &> /dev/null
if [ $? -ne 0 ]; then
  echo "You need to log in to Azure first:"
  az login
else
  echo "✅ Already logged in to Azure"
fi

# Get subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "Using subscription: $SUBSCRIPTION_ID"

# Get resource group and cluster name
read -p "Enter the resource group name (default: inspira-resources): " RESOURCE_GROUP
RESOURCE_GROUP=${RESOURCE_GROUP:-inspira-resources}

read -p "Enter the AKS cluster name (default: inspira-cluster): " CLUSTER_NAME
CLUSTER_NAME=${CLUSTER_NAME:-inspira-cluster}

# Get service principal ID
read -p "Enter the service principal client ID (from the error message): " SP_ID
if [ -z "$SP_ID" ]; then
  echo "❌ Service principal ID is required"
  exit 1
fi

echo ""
echo "===== Assigning Required Roles ====="
echo ""

# Assign the "Azure Kubernetes Service Cluster User Role"
echo "Assigning Azure Kubernetes Service Cluster User Role..."
az role assignment create \
  --assignee "$SP_ID" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.ContainerService/managedClusters/$CLUSTER_NAME" \
  --role "Azure Kubernetes Service Cluster User Role"

# Assign the "Azure Kubernetes Service Cluster Admin Role"
echo "Assigning Azure Kubernetes Service Cluster Admin Role..."
az role assignment create \
  --assignee "$SP_ID" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.ContainerService/managedClusters/$CLUSTER_NAME" \
  --role "Azure Kubernetes Service Cluster Admin Role"

# Assign the "Contributor" role on the resource group
echo "Assigning Contributor role on the resource group..."
az role assignment create \
  --assignee "$SP_ID" \
  --resource-group "$RESOURCE_GROUP" \
  --role "Contributor"

echo ""
echo "===== Verifying Permissions ====="
echo ""

# List role assignments for the service principal
echo "Role assignments for service principal $SP_ID:"
az role assignment list --assignee "$SP_ID" --all -o table

echo ""
echo "===== Next Steps ====="
echo ""
echo "1. Wait a few minutes for the permissions to propagate"
echo "2. If you're using GitHub Actions, re-run the workflow"
echo "3. If you're still experiencing issues, check the troubleshooting section in docs/ci-cd/AZURE-PERMISSIONS-GUIDE.md"
echo ""
echo "For more information on AKS permissions, see:"
echo "https://docs.microsoft.com/en-us/azure/aks/manage-azure-rbac" 