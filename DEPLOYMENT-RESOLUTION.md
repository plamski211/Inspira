# Azure Deployment Resolution Guide

This document provides a comprehensive guide to resolving the image pull issues encountered during the deployment of the Inspira microservices to Azure Kubernetes Service (AKS).

## Issue Summary

We encountered persistent image pull issues when deploying our microservices to AKS. The main error messages were:

1. `401 Unauthorized` when trying to fetch token from ACR
2. `no match for platform in manifest: not found` suggesting platform compatibility issues

## Resolution Steps

### Step 1: Fix ACR Authentication

Run the `fix-acr-auth.sh` script to create a service principal with AcrPull role and configure Kubernetes to use it:

```bash
./fix-acr-auth.sh
```

This script:
- Creates a service principal with AcrPull role for the ACR
- Creates a Kubernetes secret with the service principal credentials
- Updates deployments to use the new secret
- Restarts the deployments

### Step 2: Fix Platform Compatibility Issues

Run the `fix-platform-compatibility.sh` script to rebuild images with the correct platform compatibility:

```bash
./fix-platform-compatibility.sh
```

This script:
- Sets up Docker buildx for multi-platform builds
- Rebuilds each service image for the Linux/AMD64 platform
- Pushes the rebuilt images to ACR

### Step 3: Verify Deployment

After running both scripts, verify the deployment:

```bash
kubectl get pods -n microservices
```

If pods are still in ImagePullBackOff state, check the events:

```bash
kubectl get events -n microservices --sort-by='.lastTimestamp'
```

### Alternative Solution: Use Docker Hub

If ACR authentication issues persist, you can use Docker Hub as an alternative:

1. Create Docker Hub repositories for each service
2. Update the `push-to-dockerhub.sh` script with your Docker Hub username and credentials
3. Run the script to push images to Docker Hub:
   ```bash
   ./push-to-dockerhub.sh
   ```
4. Update your Kubernetes manifests to use Docker Hub images:
   ```bash
   sed -i '' "s|inspiraregistry20250617.azurecr.io|docker.io/yourusername|g" k8s-azure/*.yaml
   ```
5. Apply the updated manifests:
   ```bash
   kubectl apply -f k8s-azure/
   ```

## Preventive Measures for Future Deployments

1. **Use Managed Identity**: Prefer using AKS managed identity for ACR authentication:
   ```bash
   az aks update -n inspira-aks -g inspira-project --attach-acr inspiraregistry20250617
   ```

2. **Platform Compatibility**: Always build images with explicit platform targeting:
   ```bash
   docker buildx build --platform linux/amd64 -t yourimage:tag .
   ```

3. **Test Authentication**: Verify ACR access from AKS before deploying:
   ```bash
   az aks check-acr --name inspira-aks --resource-group inspira-project --acr inspiraregistry20250617.azurecr.io
   ```

4. **Use Helm Charts**: Consider using Helm for more robust deployments with better secret management

## Additional Resources

- [AKS and ACR Integration](https://docs.microsoft.com/en-us/azure/aks/cluster-container-registry-integration)
- [Docker Multi-Platform Builds](https://docs.docker.com/build/building/multi-platform/)
- [Azure Container Registry Authentication](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-authentication)
- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)

By following these steps, you should be able to resolve the image pull issues and successfully deploy your microservices to AKS. 