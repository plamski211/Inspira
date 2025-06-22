# Setting Up GitHub Secrets for CI/CD

This guide explains how to set up the required secrets for the CI/CD pipeline, particularly for Docker Hub authentication.

## Docker Hub Authentication

### Required Secrets

1. `DOCKERHUB_USERNAME`: Your Docker Hub username
2. `DOCKERHUB_TOKEN`: A Docker Hub access token (not your password)

### Steps to Create a Docker Hub Access Token

1. Log in to [Docker Hub](https://hub.docker.com)
2. Go to Account Settings > Security
3. Click "New Access Token"
4. Give it a description (e.g., "GitHub CI/CD")
5. Copy the token immediately (it won't be shown again)

### Adding Secrets to GitHub

1. Go to your repository on GitHub
2. Click on "Settings" tab
3. In the left sidebar, click on "Secrets and variables" > "Actions"
4. Click "New repository secret"
5. Add both secrets:
   - Name: `DOCKERHUB_USERNAME`
   - Value: Your Docker Hub username
   
   Then:
   - Name: `DOCKERHUB_TOKEN`
   - Value: The access token you created

### Verifying Secrets

1. After adding the secrets, they should appear in the list with their names (values will be hidden)
2. The CI/CD pipeline will automatically use these secrets for Docker Hub authentication
3. You can verify the secrets are working by checking the "Debug Docker Hub Credentials" step in the workflow runs

### Troubleshooting

If you see "Error: Username and password required":
1. Double-check that both secrets are added correctly
2. Ensure the secret names match exactly: `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN`
3. Try creating a new access token in Docker Hub and updating the `DOCKERHUB_TOKEN` secret

## Security Notes

- Never commit secrets directly to the repository
- Always use GitHub Secrets for sensitive information
- Regularly rotate your Docker Hub access tokens
- Use tokens with minimal required permissions

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