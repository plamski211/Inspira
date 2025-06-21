# Frontend White Screen Fix

This document summarizes the changes made to fix the frontend white screen issue in the Inspira platform.

## Problem

The frontend deployment to Azure was resulting in a white screen when accessing the frontend through the cloud IP.

## Root Causes

Several issues were identified:

1. **Improper Docker Image**: The frontend Docker image was not properly configured to serve the frontend application.
2. **Missing Configuration**: The `env-config.js` file was missing or not properly configured.
3. **MIME Type Issues**: JavaScript and CSS files were not being served with the correct MIME types.
4. **Deployment Configuration**: The Kubernetes deployment was not properly configured to mount the configuration files.

## Solution

The following changes were made to fix the issue:

### 1. Updated Frontend Dockerfile

The frontend Dockerfile was updated to:

- Use a multi-stage build process
- Properly copy the built assets to the Nginx container
- Configure Nginx to serve JavaScript and CSS files with the correct MIME types
- Include a fallback HTML file in case the build fails
- Create a health check endpoint

### 2. Created Configuration Files

The following configuration files were created:

- `frontend/public/env-config.js`: Contains the frontend configuration, including API URL and Auth0 settings
- `frontend/public/index.html`: A simple HTML file that serves as a fallback if the React build fails

### 3. Updated Kubernetes Deployment

The Kubernetes deployment was updated to:

- Mount the `env-config.js` file as a ConfigMap
- Configure health and readiness probes
- Set appropriate resource limits
- Use a LoadBalancer service to expose the frontend

### 4. Created Deployment Scripts

The following scripts were created to help with deployment:

- `scripts/deployment/deploy-frontend.sh`: Deploys the frontend to Azure
- `scripts/deployment/check-frontend.sh`: Checks the frontend deployment
- `scripts/deployment/fix-frontend-deployment.sh`: Fixes the frontend deployment

## How to Use the Fix

To fix the frontend white screen issue, run the following command:

```bash
./scripts/deployment/fix-frontend-deployment.sh <resource-group> <aks-cluster> <registry>
```

This script will:

1. Build a new frontend Docker image
2. Push the image to Azure Container Registry
3. Deploy the frontend to Kubernetes
4. Configure the frontend with the correct settings

## Verifying the Fix

To verify that the fix worked, run the following command:

```bash
./scripts/deployment/check-frontend.sh
```

This script will:

1. Check if the frontend service is running
2. Check if the frontend is accessible
3. Check if env-config.js is accessible
4. Display the frontend logs

You can also manually verify the fix by:

1. Accessing the frontend through the cloud IP
2. Checking the browser console for any errors
3. Checking the network requests to see if all files are loading correctly

## Additional Improvements

The following additional improvements were made:

1. **Monitoring Access Scripts**: The scripts to access Prometheus and Grafana were updated to handle port conflicts by automatically selecting an available port.
2. **Documentation**: The documentation was updated to include information about the frontend deployment and troubleshooting.

## Related Documentation

- [Frontend Deployment Guide](FRONTEND-DEPLOYMENT.md)
- [CI/CD Pipeline](../CI-CD-PIPELINE.md)
- [Azure Deployment](AZURE-DEPLOYMENT.md) 