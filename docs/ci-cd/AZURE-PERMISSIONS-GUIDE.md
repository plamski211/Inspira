# Azure AKS Permissions Guide for CI/CD Pipeline

This guide explains how to fix permission issues when deploying to Azure Kubernetes Service (AKS) from your CI/CD pipeline.

## Common Error

The following error occurs when the service principal used in your GitHub Actions workflow doesn't have sufficient permissions to access the AKS cluster:

```
ERROR: (AuthorizationFailed) The client '...' with object id '...' does not have authorization to perform action 'Microsoft.ContainerService/managedClusters/listClusterUserCredential/action' over scope '/subscriptions/.../resourceGroups/.../providers/Microsoft.ContainerService/managedClusters/...' or the scope is invalid. If access was recently granted, please refresh your credentials.
```

## Quick Solution

Run our automated fix script:

```bash
./scripts/ci-cd/fix-aks-permissions.sh
```

This script will:
1. Prompt for your resource group name, cluster name, and service principal ID
2. Assign the necessary roles to the service principal
3. Verify the role assignments

## Manual Solution

### 1. Create a Service Principal with Proper Permissions

Run the following commands to create a service principal and assign it the necessary permissions:

```bash
# Login to Azure
az login

# Create a service principal
SP=$(az ad sp create-for-rbac --name "github-actions-inspira" --role Contributor --sdk-auth)

# Get the service principal ID
SP_ID=$(echo $SP | jq -r .clientId)

# Get your subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Get your resource group name
RESOURCE_GROUP="your-resource-group-name"

# Get your AKS cluster name
AKS_CLUSTER_NAME="your-aks-cluster-name"

# Assign the "Azure Kubernetes Service Cluster User Role" to the service principal
az role assignment create \
  --assignee $SP_ID \
  --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.ContainerService/managedClusters/$AKS_CLUSTER_NAME \
  --role "Azure Kubernetes Service Cluster User Role"

# Assign the "Azure Kubernetes Service Cluster Admin Role" to the service principal
az role assignment create \
  --assignee $SP_ID \
  --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.ContainerService/managedClusters/$AKS_CLUSTER_NAME \
  --role "Azure Kubernetes Service Cluster Admin Role"

# Output the service principal credentials
echo $SP
```

### 2. Add the Service Principal Credentials to GitHub Secrets

1. Copy the entire JSON output from the last command.
2. In your GitHub repository, go to Settings > Secrets and variables > Actions.
3. Create a new repository secret named `AZURE_CREDENTIALS`.
4. Paste the JSON output as the secret value.

### 3. Set Up GitHub Variables

In your GitHub repository, go to Settings > Secrets and variables > Actions > Variables and add:

1. `AZURE_RESOURCE_GROUP` - The name of your Azure resource group
2. `AKS_CLUSTER_NAME` - The name of your AKS cluster

## Fixing Permissions for an Existing Service Principal

If you already have a service principal but it's getting the authorization error:

1. Extract the client ID from the error message (e.g., '9285ee66-0202-4672-bb23-847cd9701b59')
2. Run the following commands:

```bash
# Login to Azure
az login

# Get your subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Set your resource group and cluster name
RESOURCE_GROUP="inspira-resources"  # Replace with your resource group name
AKS_CLUSTER_NAME="inspira-cluster"  # Replace with your cluster name

# Set the service principal ID from the error message
SP_ID="9285ee66-0202-4672-bb23-847cd9701b59"  # Replace with your service principal ID

# Assign the necessary roles
az role assignment create \
  --assignee $SP_ID \
  --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.ContainerService/managedClusters/$AKS_CLUSTER_NAME \
  --role "Azure Kubernetes Service Cluster User Role"

az role assignment create \
  --assignee $SP_ID \
  --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.ContainerService/managedClusters/$AKS_CLUSTER_NAME \
  --role "Azure Kubernetes Service Cluster Admin Role"
```

3. Wait a few minutes for the permissions to propagate
4. Re-run your GitHub Actions workflow

## Alternative: Using Managed Identity

For production environments, consider using Azure Managed Identity instead of service principals for better security:

1. Enable managed identity on your Azure resources.
2. Configure your AKS cluster to use managed identity.
3. Update your GitHub Actions workflow to use managed identity authentication.

## Troubleshooting

If you still encounter permission issues:

1. Verify the service principal hasn't expired (they typically expire after 1 year).
2. Check if the resource group or AKS cluster name has changed.
3. Ensure the service principal has the correct role assignments.
4. Try recreating the service principal with fresh credentials.
5. Check for typos in resource group or cluster names.
6. Ensure the subscription is active and not suspended.

## Pipeline Resilience

Our CI/CD pipeline is designed to be resilient and will continue to run even if Azure authentication fails. It will:

1. Attempt to authenticate with Azure using the provided credentials.
2. If authentication fails, it will fall back to using mock deployments.
3. Report the authentication status in the workflow logs.

This ensures that the pipeline can still be used for demonstration and testing purposes without valid Azure credentials. 