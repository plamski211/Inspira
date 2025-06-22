#!/bin/bash
#
# This script creates a federated identity credential for GitHub Actions OIDC authentication
# It requires the Azure CLI to be installed and authenticated

set -e

# Variables
RESOURCE_GROUP="inspira-project"
AKS_CLUSTER="inspira-aks"
APP_NAME="github-actions-oidc"
GITHUB_ORG=$(git config --get remote.origin.url | sed -n 's/.*[:/]\([^/]*\)\/[^/]*$/\1/p')
GITHUB_REPO=$(git config --get remote.origin.url | sed -n 's/.*\/\([^/]*\)\.git$/\1/p')

if [ -z "$GITHUB_ORG" ] || [ -z "$GITHUB_REPO" ]; then
  echo "Could not determine GitHub organization and repository"
  echo "Please enter GitHub organization name:"
  read GITHUB_ORG
  echo "Please enter GitHub repository name:"
  read GITHUB_REPO
fi

echo "Setting up OIDC for GitHub Actions..."
echo "Organization: $GITHUB_ORG"
echo "Repository: $GITHUB_REPO"
echo "Resource Group: $RESOURCE_GROUP"
echo "AKS Cluster: $AKS_CLUSTER"

# Get Azure subscription and tenant information
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
AZURE_TENANT_ID=$(az account show --query tenantId -o tsv)

echo "Subscription ID: $SUBSCRIPTION_ID"
echo "Tenant ID: $AZURE_TENANT_ID"

# Create the application registration if it doesn't exist
APP_ID=$(az ad app list --display-name "$APP_NAME" --query "[0].appId" -o tsv)
if [ -z "$APP_ID" ]; then
  echo "Creating new app registration: $APP_NAME"
  APP_ID=$(az ad app create --display-name "$APP_NAME" --query appId -o tsv)
else
  echo "App registration already exists: $APP_NAME"
fi

echo "App ID: $APP_ID"

# Create service principal if it doesn't exist
SERVICE_PRINCIPAL_ID=$(az ad sp list --filter "appId eq '$APP_ID'" --query "[0].id" -o tsv)
if [ -z "$SERVICE_PRINCIPAL_ID" ]; then
  echo "Creating service principal"
  SERVICE_PRINCIPAL_ID=$(az ad sp create --id $APP_ID --query id -o tsv)
else
  echo "Service principal already exists"
fi

echo "Service Principal ID: $SERVICE_PRINCIPAL_ID"

# Assign contributor role to the service principal
echo "Assigning Contributor role to service principal"
az role assignment create \
  --assignee $SERVICE_PRINCIPAL_ID \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP" || echo "Role already assigned or no permission to assign roles"

# Assign AKS specific roles
echo "Assigning AKS-specific roles to service principal"
az role assignment create \
  --assignee $SERVICE_PRINCIPAL_ID \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.ContainerService/managedClusters/$AKS_CLUSTER" \
  --role "Azure Kubernetes Service Cluster User Role" || echo "Role already assigned or no permission to assign roles"
  
az role assignment create \
  --assignee $SERVICE_PRINCIPAL_ID \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.ContainerService/managedClusters/$AKS_CLUSTER" \
  --role "Azure Kubernetes Service Cluster Admin Role" || echo "Role already assigned or no permission to assign roles"

# Configure federated identity credentials for GitHub repo
echo "Creating federated identity credentials for GitHub Actions"

# For main branch workflows
az ad app federated-credential create \
  --id $APP_ID \
  --parameters "{\"name\":\"github-actions-main\",\"issuer\":\"https://token.actions.githubusercontent.com\",\"subject\":\"repo:${GITHUB_ORG}/${GITHUB_REPO}:ref:refs/heads/main\",\"audiences\":[\"api://AzureADTokenExchange\"]}" || echo "Federated credential may already exist"

# For pull requests
az ad app federated-credential create \
  --id $APP_ID \
  --parameters "{\"name\":\"github-actions-pr\",\"issuer\":\"https://token.actions.githubusercontent.com\",\"subject\":\"repo:${GITHUB_ORG}/${GITHUB_REPO}:pull_request\",\"audiences\":[\"api://AzureADTokenExchange\"]}" || echo "Federated credential may already exist"

# For environment-specific workflows
for env in staging production; do
  az ad app federated-credential create \
    --id $APP_ID \
    --parameters "{\"name\":\"github-actions-$env\",\"issuer\":\"https://token.actions.githubusercontent.com\",\"subject\":\"repo:${GITHUB_ORG}/${GITHUB_REPO}:environment:$env\",\"audiences\":[\"api://AzureADTokenExchange\"]}" || echo "Federated credential may already exist"
done

# Print instructions for GitHub setup
echo ""
echo "====== GitHub Secret Setup ======"
echo "Add the following secrets to your GitHub repository:"
echo ""
echo "AZURE_CLIENT_ID: $APP_ID"
echo "AZURE_TENANT_ID: $AZURE_TENANT_ID"
echo "AZURE_SUBSCRIPTION_ID: $SUBSCRIPTION_ID"
echo ""
echo "Also ensure you have the following repository secrets for other Azure resources:"
echo "AKS_RESOURCE_GROUP: $RESOURCE_GROUP"
echo "AKS_CLUSTER_NAME: $AKS_CLUSTER"
echo ""
echo "Script complete!" 