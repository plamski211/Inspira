#!/bin/bash
# push-to-azure.sh - Script to build and push images to Azure Container Registry

set -e

# Azure Container Registry details
ACR_NAME="inspiraregistry20250617"
ACR_LOGIN_SERVER="${ACR_NAME}.azurecr.io"

# Login to Azure Container Registry
echo "Logging in to Azure Container Registry..."
az acr login --name $ACR_NAME

# Build and push user-service
echo "Building and pushing user-service..."
cd user-service
docker build -t ${ACR_LOGIN_SERVER}/user-service:latest .
docker push ${ACR_LOGIN_SERVER}/user-service:latest
cd ..

# Build and push frontend
echo "Building and pushing frontend..."
cd frontend
docker build -t ${ACR_LOGIN_SERVER}/frontend:latest -f Dockerfile.prod .
docker push ${ACR_LOGIN_SERVER}/frontend:latest
cd ..

# Update Kubernetes deployments
echo "Updating Kubernetes deployments to use Azure Container Registry images..."

# Update user-service deployment
kubectl set image deployment/user-service -n microservices user-service=${ACR_LOGIN_SERVER}/user-service:latest

# Update frontend deployment
kubectl set image deployment/frontend -n microservices frontend=${ACR_LOGIN_SERVER}/frontend:latest

echo "Verifying deployments..."
kubectl get pods -n microservices

echo "Done! Your services are now deployed using Azure Container Registry images." 