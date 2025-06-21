# Azure Permissions Guide for CI/CD Pipeline

This guide explains the Azure permissions required for the CI/CD pipeline to deploy to Azure Kubernetes Service (AKS).

## Common Permission Errors

### AuthorizationFailed Error

If you see an error like this:

```
ERROR: (AuthorizationFailed) The client '9285ee66-0202-4672-bb23-847cd9701b59' with object id '9285ee66-0202-4672-bb23-847cd9701b59' does not have authorization to perform action 'Microsoft.ContainerService/managedClusters/listClusterUserCredential/action' over scope '/subscriptions/0e46a8f2-8dd8-4c4e-841f-94a20add816d/resourceGroups/inspira-resources/providers/Microsoft.ContainerService/managedClusters/inspira-cluster' or the scope is invalid. If access was recently granted, please refresh your credentials.
```

This means the service principal or user account used by the CI/CD pipeline doesn't have the necessary permissions to access the AKS cluster.

## Required Permissions

The service principal or user account used by the CI/CD pipeline needs the following permissions:

1. **Azure Kubernetes Service Cluster User Role**: Allows getting credentials to access the cluster
2. **Azure Kubernetes Service Cluster Admin Role**: Allows administrative actions on the cluster
3. **Contributor Role**: Allows managing resources in the resource group

## Fixing Permission Issues

### Using the Fix Script

We've provided a script to fix permission issues automatically:

```bash
# Run the script with default values
./scripts/ci-cd/fix-aks-permissions.sh

# Or specify subscription, resource group, and cluster name
./scripts/ci-cd/fix-aks-permissions.sh "your-subscription-id" "your-resource-group" "your-cluster-name"
```

### Manual Steps

If you prefer to fix permissions manually:

1. **Identify the Service Principal ID**:
   - For GitHub Actions, it's the client ID from the error message
   - For Azure DevOps, it's the service connection's service principal

2. **Assign the Required Roles**:
   ```bash
   # Get your subscription ID
   SUBSCRIPTION_ID=$(az account show --query id -o tsv)
   
   # Set your resource group and cluster name
   RESOURCE_GROUP="inspira-resources"
   CLUSTER_NAME="inspira-cluster"
   
   # Set the service principal ID
   SP_ID="the-service-principal-id"
   
   # Assign the Azure Kubernetes Service Cluster User Role
   az role assignment create \
     --assignee "$SP_ID" \
     --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.ContainerService/managedClusters/$CLUSTER_NAME" \
     --role "Azure Kubernetes Service Cluster User Role"
   
   # Assign the Azure Kubernetes Service Cluster Admin Role
   az role assignment create \
     --assignee "$SP_ID" \
     --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.ContainerService/managedClusters/$CLUSTER_NAME" \
     --role "Azure Kubernetes Service Cluster Admin Role"
   
   # Assign the Contributor role on the resource group
   az role assignment create \
     --assignee "$SP_ID" \
     --resource-group "$RESOURCE_GROUP" \
     --role "Contributor"
   ```

## Setting Up GitHub Actions Azure Credentials

To set up Azure credentials for GitHub Actions:

1. **Create a Service Principal**:
   ```bash
   az ad sp create-for-rbac --name "inspira-github-actions" \
     --role contributor \
     --scopes /subscriptions/$(az account show --query id -o tsv)/resourceGroups/inspira-resources \
     --sdk-auth
   ```

2. **Add the Output JSON as a GitHub Secret**:
   - Copy the entire JSON output
   - Go to your GitHub repository
   - Navigate to Settings > Secrets > New repository secret
   - Name: `AZURE_CREDENTIALS`
   - Value: Paste the JSON output

3. **Use the Credentials in GitHub Actions**:
   ```yaml
   - name: Azure login
     uses: azure/login@v1
     with:
       creds: ${{ secrets.AZURE_CREDENTIALS }}
   ```

## Troubleshooting

If you're still experiencing permission issues:

1. **Check Role Assignments**:
   ```bash
   az role assignment list --assignee "service-principal-id" --all -o table
   ```

2. **Verify Resource Group and Cluster Existence**:
   ```bash
   az group show --name "inspira-resources"
   az aks show --resource-group "inspira-resources" --name "inspira-cluster"
   ```

3. **Check for Typos in Resource Names**:
   - Ensure the resource group and cluster names in your workflow match the actual names in Azure

4. **Wait for Permissions to Propagate**:
   - Azure RBAC changes can take a few minutes to propagate

5. **Regenerate Service Principal**:
   - If all else fails, create a new service principal and update your secrets

## Additional Resources

- [Azure RBAC Documentation](https://docs.microsoft.com/en-us/azure/role-based-access-control/overview)
- [AKS RBAC Documentation](https://docs.microsoft.com/en-us/azure/aks/manage-azure-rbac)
- [GitHub Actions with Azure](https://docs.microsoft.com/en-us/azure/developer/github/connect-from-github) 