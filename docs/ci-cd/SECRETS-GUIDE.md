# GitHub Secrets Guide

## Required Secrets

For our CI/CD pipeline, we need:

1. Docker Hub Credentials:
   - `DOCKER_PASSWORD`: Your Docker Hub password

2. Azure Container Registry Credentials:
   - `ACR_LOGIN_SERVER`: `inspiraregistry20250617.azurecr.io`
   - `ACR_USERNAME`: `inspiraregistry20250617`
   - `ACR_PASSWORD`: The password from Azure CLI (use the first password)

## How to Get Azure Credentials

1. Login to Azure:
   ```bash
   az login
   ```

2. View your Azure Container Registry:
   ```bash
   az acr list --query "[].{name:name, loginServer:loginServer, resourceGroup:resourceGroup}" -o table
   ```

3. Get ACR credentials:
   ```bash
   az acr credential show --name inspiraregistry20250617
   ```

## How to Add Secrets

1. Go to your GitHub repository in a web browser
2. Click "Settings" at the top
3. In the left sidebar, click "Secrets and variables" → "Actions"
4. Click "New repository secret"
5. Add each secret:
   - Name: (e.g., `ACR_PASSWORD`)
   - Value: The corresponding value
6. Click "Add secret"

## How Secrets are Used

```yaml
# Example in .github/workflows/ci-cd.yml
steps:
  # Docker Hub Login
  - name: Login to Docker Hub
    uses: docker/login-action@v2
    with:
      username: pngbanks
      password: ${{ secrets.DOCKER_PASSWORD }}

  # Azure Container Registry Login
  - name: Login to Azure Container Registry
    uses: docker/login-action@v2
    with:
      registry: ${{ secrets.ACR_LOGIN_SERVER }}
      username: ${{ secrets.ACR_USERNAME }}
      password: ${{ secrets.ACR_PASSWORD }}
```

## Security Best Practices

1. Never commit passwords or credentials in code files
2. Always use GitHub Secrets for sensitive information
3. If credentials are accidentally committed:
   - Change the passwords/credentials immediately
   - Remove them from the git history
   - Create new secrets in GitHub Settings
4. Rotate Azure credentials periodically:
   ```bash
   az acr credential renew --name inspiraregistry20250617 --password-name password
   ```

## Troubleshooting

1. Docker Hub Authentication Issues:
   - Check if `DOCKER_PASSWORD` is set correctly
   - Try logging in locally: `docker login -u pngbanks`

2. Azure Authentication Issues:
   - Verify Azure credentials are current
   - Check if all ACR secrets are set correctly
   - Try logging in locally: `az acr login --name inspiraregistry20250617` 