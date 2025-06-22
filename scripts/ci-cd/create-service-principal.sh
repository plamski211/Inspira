#!/bin/bash
#
# This script creates a new service principal with a client secret for Azure authentication
# It requires the Azure CLI to be installed and authenticated

set -e

# Variables
RESOURCE_GROUP="inspira-project"
AKS_CLUSTER="inspira-aks"
SP_NAME="inspira-github-actions-$(date +%Y%m%d)"

echo "Creating new service principal: $SP_NAME"
echo "Resource Group: $RESOURCE_GROUP"
echo "AKS Cluster: $AKS_CLUSTER"

# Get Azure subscription information
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "Subscription ID: $SUBSCRIPTION_ID"

# Create service principal with contributor role
echo "Creating service principal with Contributor role..."
SP_JSON=$(az ad sp create-for-rbac \
  --name "$SP_NAME" \
  --role "Contributor" \
  --scopes "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP" \
  --sdk-auth)

# Extract values from the JSON
CLIENT_ID=$(echo $SP_JSON | jq -r '.clientId')
CLIENT_SECRET=$(echo $SP_JSON | jq -r '.clientSecret')
TENANT_ID=$(echo $SP_JSON | jq -r '.tenantId')

echo "Service Principal created successfully!"
echo "Client ID: $CLIENT_ID"
echo "Tenant ID: $TENANT_ID"

# Assign AKS specific roles
echo "Assigning AKS-specific roles..."
az role assignment create \
  --assignee "$CLIENT_ID" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.ContainerService/managedClusters/$AKS_CLUSTER" \
  --role "Azure Kubernetes Service Cluster User Role" || echo "Role already assigned or no permission to assign roles"
  
az role assignment create \
  --assignee "$CLIENT_ID" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.ContainerService/managedClusters/$AKS_CLUSTER" \
  --role "Azure Kubernetes Service Cluster Admin Role" || echo "Role already assigned or no permission to assign roles"

# Print instructions for GitHub setup
echo ""
echo "====== GitHub Secret Setup ======"
echo "Add the following secret to your GitHub repository:"
echo ""
echo "AZURE_CREDENTIALS:"
echo "$SP_JSON"
echo ""
echo "Or, if you prefer to use the individual values:"
echo "AZURE_CLIENT_ID: $CLIENT_ID"
echo "AZURE_CLIENT_SECRET: $CLIENT_SECRET"
echo "AZURE_TENANT_ID: $TENANT_ID"
echo "AZURE_SUBSCRIPTION_ID: $SUBSCRIPTION_ID"
echo ""
echo "Script complete!" 