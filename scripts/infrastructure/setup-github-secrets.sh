#!/bin/bash

# Script to set up GitHub secrets for CI/CD pipeline
# Usage: ./setup-github-secrets.sh <github-repo> <azure-subscription-id>

set -e

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <github-repo> <azure-subscription-id>"
    echo "Example: $0 myorg/inspira-project 12345678-1234-1234-1234-123456789012"
    exit 1
fi

GITHUB_REPO=$1
AZURE_SUBSCRIPTION_ID=$2
RESOURCE_GROUP="inspira-project"
ACR_NAME="inspiraregistry20250617"
AKS_NAME="inspira-aks"

echo "Setting up GitHub secrets for $GITHUB_REPO"
echo "Using Azure subscription: $AZURE_SUBSCRIPTION_ID"
echo "Resource Group: $RESOURCE_GROUP"
echo "ACR Name: $ACR_NAME"
echo "AKS Name: $AKS_NAME"

# Check if the GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "GitHub CLI is not installed. Please install it first."
    echo "https://github.com/cli/cli#installation"
    exit 1
fi

# Check if logged in to GitHub
if ! gh auth status &> /dev/null; then
    echo "Not logged in to GitHub. Please run 'gh auth login' first."
    exit 1
fi

# Check if logged in to Azure
if ! az account show &> /dev/null; then
    echo "Not logged in to Azure. Please run 'az login' first."
    exit 1
fi

# Set the subscription
echo "Setting Azure subscription..."
az account set --subscription "$AZURE_SUBSCRIPTION_ID"

# Get ACR credentials
echo "Getting ACR credentials..."
ACR_USERNAME=$(az acr credential show --name "$ACR_NAME" --query "username" -o tsv)
ACR_PASSWORD=$(az acr credential show --name "$ACR_NAME" --query "passwords[0].value" -o tsv)

# Create service principal for AKS
echo "Creating service principal for AKS..."
SP_NAME="inspira-github-actions"
SP_OUTPUT=$(az ad sp create-for-rbac --name "$SP_NAME" --role contributor --scopes /subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP --sdk-auth)

# Set GitHub secrets
echo "Setting GitHub secrets..."
echo $SP_OUTPUT | gh secret set AZURE_CREDENTIALS --repo "$GITHUB_REPO"
echo $ACR_USERNAME | gh secret set ACR_USERNAME --repo "$GITHUB_REPO"
echo $ACR_PASSWORD | gh secret set ACR_PASSWORD --repo "$GITHUB_REPO"

echo "Done! The following secrets have been set in your GitHub repository:"
echo "- AZURE_CREDENTIALS: Service principal credentials for Azure"
echo "- ACR_USERNAME: Azure Container Registry username"
echo "- ACR_PASSWORD: Azure Container Registry password"

echo "You can now use these secrets in your GitHub Actions workflows." 