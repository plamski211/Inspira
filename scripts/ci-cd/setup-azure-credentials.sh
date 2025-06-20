#!/bin/bash

# Script to set up Azure credentials for CI/CD pipeline

echo "===== Azure Credentials Setup for CI/CD ====="
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

echo ""
echo "Creating service principal for GitHub Actions..."

# Generate a service principal with Contributor role
echo "This will create a service principal with Contributor role on your subscription."
echo "You can change the role or scope later if needed."
echo ""

read -p "Enter a name for the service principal (default: github-actions-inspira): " sp_name
sp_name=${sp_name:-github-actions-inspira}

echo "Creating service principal: $sp_name"
az ad sp create-for-rbac --name "$sp_name" --role Contributor --sdk-auth

echo ""
echo "===== Instructions ====="
echo "1. Copy the entire JSON output above."
echo "2. In your GitHub repository, go to Settings > Secrets and variables > Actions."
echo "3. Create a new repository secret named 'AZURE_CREDENTIALS'."
echo "4. Paste the JSON output as the secret value."
echo ""

echo "For AKS cluster access, ensure the service principal has the appropriate role:"
echo "az role assignment create --assignee [service_principal_id] --scope /subscriptions/[subscription_id]/resourceGroups/[resource_group]/providers/Microsoft.ContainerService/managedClusters/[cluster_name] --role 'Azure Kubernetes Service Cluster User Role'"
echo ""

echo "You also need to set up the following GitHub variables:"
echo "1. AZURE_RESOURCE_GROUP - The name of your Azure resource group"
echo "2. AKS_CLUSTER_NAME - The name of your AKS cluster"
echo ""

echo "Azure credentials setup completed!" 