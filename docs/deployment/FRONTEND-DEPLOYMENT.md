# Frontend Deployment Guide

This guide explains how to deploy and troubleshoot the frontend application in the Inspira platform.

## Prerequisites

- Docker installed
- kubectl installed
- Azure CLI installed
- Access to Azure Container Registry
- Access to Azure Kubernetes Service (AKS)

## Deployment Scripts

The following scripts are available to help with frontend deployment:

1. `scripts/deployment/deploy-frontend.sh` - Deploys the frontend to Azure
2. `scripts/deployment/check-frontend.sh` - Checks the frontend deployment
3. `scripts/deployment/fix-frontend-deployment.sh` - Fixes the frontend deployment

## Manual Deployment Steps

### 1. Build the Frontend Docker Image

```bash
# Navigate to the frontend directory
cd frontend

# Build the Docker image
docker build -t <registry-name>.azurecr.io/frontend:latest .
```

### 2. Push the Docker Image to Azure Container Registry

```bash
# Log in to Azure Container Registry
az acr login --name <registry-name>

# Push the Docker image
docker push <registry-name>.azurecr.io/frontend:latest
```

### 3. Deploy to Kubernetes

```bash
# Apply the deployment
kubectl apply -f k8s/base/frontend-deployment.yaml
```

## Troubleshooting White Screen Issues

If you're experiencing a white screen when accessing the frontend, follow these troubleshooting steps:

### 1. Check the Frontend Logs

```bash
kubectl logs deployment/frontend
```

Look for any errors or warnings in the logs.

### 2. Check if the Frontend Service is Running

```bash
kubectl get service frontend
```

Make sure the service has an external IP assigned.

### 3. Check if env-config.js is Properly Configured

The frontend application requires an `env-config.js` file to be properly configured. This file should be mounted as a ConfigMap in the Kubernetes deployment.

```bash
kubectl get configmap frontend-config -o yaml
```

The ConfigMap should contain the `env-config.js` file with the correct configuration.

### 4. Check Browser Console for Errors

Open the browser developer tools (F12) and check the console for any JavaScript errors.

### 5. Check Network Requests

In the browser developer tools, go to the Network tab and check if there are any failed requests, particularly to the API Gateway.

## Common Issues and Solutions

### MIME Type Issues

If you're seeing errors related to MIME types in the browser console, make sure the Nginx configuration in the Docker image is correctly set up to serve JavaScript and CSS files with the proper MIME types.

### API Gateway Connection Issues

If the frontend can't connect to the API Gateway, check the following:

1. Make sure the API Gateway service is running
2. Check if the API Gateway is accessible from the frontend
3. Check if the `env-config.js` file has the correct API URL

### Missing Files

If the frontend is missing files, check the Docker image to make sure all files are correctly copied to the image.

## Using the Fix Script

If you're still experiencing issues, you can use the `fix-frontend-deployment.sh` script to fix the frontend deployment:

```bash
./scripts/deployment/fix-frontend-deployment.sh <resource-group> <aks-cluster> <registry>
```

This script will:

1. Build a new frontend Docker image
2. Push the image to Azure Container Registry
3. Deploy the frontend to Kubernetes
4. Configure the frontend with the correct settings

## Verifying the Deployment

After deploying the frontend, you can verify the deployment using the `check-frontend.sh` script:

```bash
./scripts/deployment/check-frontend.sh
```

This script will:

1. Check if the frontend service is running
2. Check if the frontend is accessible
3. Check if env-config.js is accessible
4. Display the frontend logs 