# Setting Up GitHub Secrets for CI/CD

This document explains how to set up the required GitHub Secrets for the CI/CD pipelines to work correctly.

## Docker Hub Authentication

The CI/CD pipelines use Docker Hub to store and retrieve container images. You need to set up the following secrets:

1. **DOCKER_PASSWORD**: Your Docker Hub account password or access token (recommended)

### Steps to create a Docker Hub access token:

1. Log in to your Docker Hub account at https://hub.docker.com/
2. Click on your username in the top right corner and select "Account Settings"
3. In the left sidebar, click on "Security"
4. Under "Access Tokens", click "New Access Token"
5. Give it a name like "GitHub Actions" and select the appropriate permissions (Read & Write)
6. Click "Generate" and copy the token that is displayed

### Steps to add the secret to GitHub:

1. Go to your GitHub repository
2. Click on "Settings" tab
3. In the left sidebar, click on "Secrets and variables" → "Actions"
4. Click "New repository secret"
5. Name: `DOCKER_PASSWORD`
6. Value: Paste your Docker Hub password or access token
7. Click "Add secret"

## Azure Authentication

For deploying to Azure Kubernetes Service, the following secrets are needed:

1. **AZURE_CREDENTIALS**: JSON credentials for Azure authentication
2. **ACR_USERNAME**: Azure Container Registry username
3. **ACR_PASSWORD**: Azure Container Registry password
4. **ACR_LOGIN_SERVER**: Azure Container Registry server URL
5. **AKS_RESOURCE_GROUP**: Resource group name for your AKS cluster
6. **AKS_CLUSTER_NAME**: Name of your AKS cluster
7. **KUBE_CONFIG**: Base64-encoded kubeconfig file for AKS access

Follow the Azure documentation to obtain these credentials and add them as GitHub Secrets using the same process described above.

## Troubleshooting

If you encounter authentication errors in your CI/CD pipeline:

1. Check that all required secrets are set correctly
2. Verify that your Docker Hub credentials are valid
3. For Docker Hub, consider using an access token instead of your password for better security
4. Check the expiration date of your Azure credentials and tokens 