# Kubernetes Manifests Guide for CI/CD Pipeline

This guide explains how to handle Kubernetes manifest issues in the CI/CD pipeline.

## Missing Kubernetes Manifests Error

### Issue

When running the deployment step in GitHub Actions, you might encounter this error:

```
sed: can't read k8s-azure/api-gateway-deployment.yaml: No such file or directory
Error: Process completed with exit code 2.
```

This happens when the pipeline tries to update Kubernetes manifest files in a directory that doesn't exist.

### Solution

Our CI/CD pipeline includes several mechanisms to handle this:

1. **Automatic Manifest Generation**: The pipeline automatically creates Kubernetes manifest files if they don't exist.

2. **Manifest Preparation Script**: A dedicated script (`scripts/ci-cd/prepare-k8s-manifests.sh`) prepares all necessary manifests.

3. **Fallback Mechanism**: If the preparation script isn't found, a simple inline fallback is used.

## How the Pipeline Handles Manifests

1. **Directory Creation**: The pipeline first creates a `k8s-azure` directory if it doesn't exist.

2. **Base Manifest Copying**: If base manifests exist in `k8s/base`, they are copied to the `k8s-azure` directory.

3. **Manifest Generation**: If no base manifests exist, simple manifests are created for each service.

4. **Image Tag Updates**: The pipeline then updates the image tags in the manifests with the current build's image tags.

## How to Fix Manually

If you need to create Kubernetes manifests manually:

1. Create a directory for your manifests:
   ```bash
   mkdir -p k8s-azure
   ```

2. Create deployment manifests for each service:
   ```bash
   # Example for api-gateway
   cat > k8s-azure/api-gateway-deployment.yaml << 'EOF'
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: api-gateway
     namespace: default
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: api-gateway
     template:
       metadata:
         labels:
           app: api-gateway
       spec:
         containers:
         - name: api-gateway
           image: inspira/api-gateway:latest
           ports:
           - containerPort: 8080
   EOF
   ```

3. Repeat for each service (frontend, user-service, content-service, media-service).

## Manifest Preparation Script

The `scripts/ci-cd/prepare-k8s-manifests.sh` script automates the creation of Kubernetes manifests:

1. It checks if base manifests exist in `k8s/base` and copies them if they do.
2. If no base manifests exist, it creates simple manifests for each service.
3. It generates all necessary resources (Deployments, Services, Ingress, ConfigMaps).

## Pipeline Resilience

Our CI/CD pipeline is designed to be resilient to missing Kubernetes manifests by:

1. Checking for manifests before updating them
2. Creating them if they don't exist
3. Using fallback mechanisms if the primary method fails
4. Providing detailed error messages and verification steps

This ensures that the pipeline can continue even if some components are missing, making it ideal for demonstration and learning purposes. 