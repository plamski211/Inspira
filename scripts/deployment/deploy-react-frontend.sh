#!/bin/bash
# This script deploys the React frontend to the Kubernetes cluster

set -e

echo "===== Starting deployment of React frontend ====="

# Make sure we're in the frontend directory
cd ../../frontend

# Build the frontend for production
echo "Building frontend for production..."
npm ci
npm run build

# Check for the Dockerfile
if [ ! -f "Dockerfile" ]; then
  echo "Error: Dockerfile not found in frontend directory"
  exit 1
fi

# Build Docker image
echo "Building Docker image..."
docker build -t inspira-frontend:latest .

# Tag for Azure Container Registry
echo "Tagging image for Azure Container Registry..."
docker tag inspira-frontend:latest inspiraacr.azurecr.io/inspira-frontend:latest

# Push to Azure Container Registry
echo "Pushing to Azure Container Registry..."
az acr login --name inspiraacr
docker push inspiraacr.azurecr.io/inspira-frontend:latest

# Check if the deployment exists
FRONTEND_DEPLOYMENT=$(kubectl get deployment frontend-deployment -n microservices 2>/dev/null || echo "")

if [ -z "$FRONTEND_DEPLOYMENT" ]; then
  # Create the deployment
  echo "Creating new frontend deployment..."
  kubectl apply -f ../../infrastructure/kubernetes/frontend-deployment.yaml
else
  # Update the deployment with the new image
  echo "Updating existing frontend deployment..."
  kubectl set image deployment/frontend-deployment frontend-container=inspiraacr.azurecr.io/inspira-frontend:latest -n microservices
  
  # Restart the deployment to ensure the new image is pulled
  kubectl rollout restart deployment/frontend-deployment -n microservices
fi

# Wait for deployment to complete
echo "Waiting for deployment to complete..."
kubectl rollout status deployment/frontend-deployment -n microservices

echo "===== React frontend deployment complete ====="
echo "To access the frontend, use the service's LoadBalancer IP or the Ingress address."
echo "You can get the LoadBalancer IP with: kubectl get service frontend-service -n microservices" 