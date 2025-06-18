# Frontend Deployment Guide

This document provides instructions for deploying the Inspira frontend application to Azure Kubernetes Service (AKS).

## Current Status

The frontend is currently deployed as a static HTML page served by an NGINX container. The application is accessible at http://4.156.37.48/.

## Deployment Options

### Option 1: Using the Simple NGINX Deployment (Current Setup)

This approach uses a standard NGINX image with a ConfigMap to inject a custom HTML page. This is the simplest approach and is currently working.

```bash
# Apply the frontend deployment
kubectl apply -f k8s-public/frontend-deployment.yaml
```

### Option 2: Using a Multi-Platform Docker Image

To deploy the actual React frontend application, you need to build a multi-platform Docker image that is compatible with both AMD64 and ARM64 architectures.

1. Use the provided script to build and push a multi-platform image:

```bash
./build-multiplatform-frontend.sh
```

2. Apply the deployment:

```bash
kubectl apply -f k8s-public/frontend-multiplatform.yaml
```

### Option 3: Using the Production Build Script

For a more automated approach, use the production build script:

```bash
./build-frontend-prod.sh
```

This script:
1. Builds a multi-platform Docker image
2. Pushes the image to Docker Hub
3. Updates the Kubernetes deployment
4. Applies the changes to the cluster

## Troubleshooting

### Platform Compatibility Issues

If you encounter platform compatibility issues (ErrImagePull with "no match for platform in manifest"), it means the Docker image was built for a different architecture than what the AKS nodes are using.

Solution: Use the multi-platform build approach with Docker Buildx as described in Option 2.

### Image Pull Errors

If you see image pull errors, check:

1. The image exists in the specified registry
2. The image tag is correct
3. The cluster has access to pull from the registry

## Accessing the Application

The frontend application is accessible at the external IP of the ingress controller:

http://4.156.37.48/

## Updating the Frontend

To update the frontend:

1. Make your changes to the frontend code
2. Run one of the build scripts mentioned above
3. Verify the deployment is successful
4. Access the application to confirm the changes 