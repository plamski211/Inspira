# Azure Deployment Troubleshooting

## Current Issues

We're experiencing image pull issues when deploying our microservices to AKS. Here's a summary of the problems and attempted solutions:

### Image Pull Issues

1. **Authentication Issues**: 
   - Pods are unable to pull images from Azure Container Registry (ACR)
   - Error: `401 Unauthorized` when trying to fetch token from ACR
   - Error: `no match for platform in manifest: not found` which suggests platform compatibility issues

2. **Authentication Attempts**:
   - Created Kubernetes secret `acr-auth` with ACR credentials
   - Updated default service account with `imagePullSecrets`
   - Attached ACR to AKS using `az aks update -n inspira-aks -g inspira-project --attach-acr inspiraregistry20250617`
   - Created a new secret from Docker config file
   - Verified ACR access from AKS with `az aks check-acr` which reported success

3. **Verification**:
   - Successfully deployed a public image (nginx) to the cluster
   - Confirmed images exist in ACR with correct tags

## Next Steps

1. **Fix ACR Authentication**:
   - Create a service principal with AcrPull role:
     ```
     SP_PASSWORD=$(az ad sp create-for-rbac --name inspira-acr-service-principal --role AcrPull --scopes $(az acr show --name inspiraregistry20250617 --query id --output tsv) --query password --output tsv)
     SP_APP_ID=$(az ad sp list --display-name inspira-acr-service-principal --query [].appId --output tsv)
     ```
   - Create a Kubernetes secret with the service principal credentials:
     ```
     kubectl create secret docker-registry acr-sp-secret \
       --namespace microservices \
       --docker-server=inspiraregistry20250617.azurecr.io \
       --docker-username=$SP_APP_ID \
       --docker-password=$SP_PASSWORD
     ```
   - Update deployments to use the new secret:
     ```
     kubectl patch deployment api-gateway -n microservices --patch '{"spec": {"template": {"spec": {"imagePullSecrets": [{"name": "acr-sp-secret"}]}}}}'
     ```

2. **Alternative: Use Docker Hub**:
   - Create repositories in Docker Hub for each service
   - Push images to Docker Hub
   - Update deployments to use Docker Hub images

3. **Check Platform Compatibility**:
   - Ensure images are built for the correct platform (Linux/AMD64)
   - Add platform flags when building images:
     ```
     docker buildx build --platform linux/amd64 -t inspiraregistry20250617.azurecr.io/api-gateway:latest .
     ```

4. **Verify Network Connectivity**:
   - Ensure AKS nodes have network access to ACR
   - Check if any network policies or firewalls are blocking access

5. **Check AKS Managed Identity**:
   - Verify the managed identity has proper permissions to ACR
   - Check if the identity is correctly configured

## Documentation Resources

- [Pull images from ACR to AKS](https://learn.microsoft.com/en-us/azure/aks/cluster-container-registry-integration)
- [Authenticate with ACR from AKS](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-auth-kubernetes)
- [Troubleshoot common AKS issues](https://learn.microsoft.com/en-us/azure/aks/troubleshooting) 