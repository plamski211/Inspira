# Azure Deployment Guide for Inspira Microservices Project

This document outlines the steps taken to deploy the Inspira microservices project to Azure Kubernetes Service (AKS).

## Architecture Overview

The Inspira project consists of the following components:

- **Frontend**: React-based web application
- **API Gateway**: Spring Boot service that routes requests to appropriate microservices
- **User Service**: Spring Boot service for user management
- **Content Service**: Spring Boot service for content management
- **Media Service**: Spring Boot service for media processing
- **PostgreSQL Databases**: Separate databases for each service
- **Azure Blob Storage**: For storing media files

## Prerequisites

- Azure CLI installed and configured
- Docker installed
- kubectl installed
- Access to an Azure subscription

## Step 1: Azure Resource Creation

1. Create a resource group:
   ```bash
   RESOURCE_GROUP=inspira-project
   LOCATION=eastus
   az group create --name $RESOURCE_GROUP --location $LOCATION
   ```

2. Create Azure Container Registry (ACR):
   ```bash
   ACR_NAME=inspiraregistry$(date +%Y%m%d)
   az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku Standard
   ```

3. Create Azure Kubernetes Service (AKS) cluster:
   ```bash
   CLUSTER_NAME=inspira-aks
   az aks create --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --node-count 2 --enable-addons monitoring --generate-ssh-keys --attach-acr $ACR_NAME --node-vm-size Standard_B2s
   ```

4. Create Azure Database for PostgreSQL servers:
   ```bash
   ./setup-azure-db.sh
   ```

5. Create Azure Storage Account:
   ```bash
   STORAGE_ACCOUNT=inspirastorage$(date +%Y%m%d)
   az storage account create --name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP --location $LOCATION --sku Standard_LRS --kind StorageV2
   ```

## Step 2: Docker Image Building and Pushing

1. Log in to Azure Container Registry:
   ```bash
   az acr login --name $ACR_NAME
   ```

2. Build and push Docker images:
   ```bash
   ./build-push.sh
   ```

## Step 3: Kubernetes Deployment

1. Get AKS credentials:
   ```bash
   az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME
   ```

2. Create namespace:
   ```bash
   kubectl create namespace microservices
   ```

3. Create Kubernetes secrets:
   ```bash
   kubectl create secret generic db-secrets --namespace microservices \
       --from-literal=users-db-url=jdbc:postgresql://$USERS_DB_SERVER.postgres.database.azure.com:5432/$USERS_DB_NAME \
       --from-literal=users-db-user=$USERS_DB_USER \
       --from-literal=users-db-password=$USERS_DB_PASSWORD \
       --from-literal=content-db-url=jdbc:postgresql://$CONTENT_DB_SERVER.postgres.database.azure.com:5432/$CONTENT_DB_NAME \
       --from-literal=content-db-user=$CONTENT_DB_USER \
       --from-literal=content-db-password=$CONTENT_DB_PASSWORD \
       --from-literal=media-db-url=jdbc:postgresql://$MEDIA_DB_SERVER.postgres.database.azure.com:5432/$MEDIA_DB_NAME \
       --from-literal=media-db-user=$MEDIA_DB_USER \
       --from-literal=media-db-password=$MEDIA_DB_PASSWORD

   kubectl create secret generic storage-secrets --namespace microservices \
       --from-literal=storage-account-name=$STORAGE_ACCOUNT \
       --from-literal=storage-account-key=$(az storage account keys list --resource-group $RESOURCE_GROUP --account-name $STORAGE_ACCOUNT --query '[0].value' -o tsv)
   ```

4. Update Kubernetes manifests:
   ```bash
   ./update-k8s-manifests.sh
   ```

5. Apply Kubernetes manifests:
   ```bash
   kubectl apply -f k8s-azure/
   ```

## Step 4: Validation

1. Check deployment status:
   ```bash
   ./validate-deployment.sh
   ```

2. Access the application:
   ```bash
   kubectl get ingress -n microservices
   ```

## Step 5: CI/CD Setup

1. Create GitHub repository secrets:
   - AZURE_CREDENTIALS: Service principal credentials
   - ACR_USERNAME: ACR username
   - ACR_PASSWORD: ACR password

2. Add GitHub Actions workflow file:
   ```bash
   mkdir -p .github/workflows
   cp azure-deploy.yml .github/workflows/
   ```

## Troubleshooting

1. Check pod status:
   ```bash
   kubectl get pods -n microservices
   ```

2. Check pod logs:
   ```bash
   kubectl logs -n microservices <pod-name>
   ```

3. Check service status:
   ```bash
   kubectl get services -n microservices
   ```

4. Check ingress status:
   ```bash
   kubectl get ingress -n microservices
   ```

5. Check AKS-ACR integration:
   ```bash
   az aks update --name $CLUSTER_NAME --resource-group $RESOURCE_GROUP --attach-acr $ACR_NAME
   ```

## Cleanup

To delete all resources when they are no longer needed:

```bash
az group delete --name $RESOURCE_GROUP --yes --no-wait
``` 