#!/bin/bash

# Script to build and push the production frontend image
# Usage: ./build-frontend-prod.sh <docker-hub-username>

set -e

# Configuration
IMAGE_NAME="pngbanks/frontend"
TAG="prod"
PLATFORMS="linux/amd64,linux/arm64"

echo "Building multi-platform frontend image..."

# Navigate to frontend directory
cd frontend

# Build the multi-platform image
docker buildx create --use --name multi-platform-builder || true
docker buildx build --platform $PLATFORMS -t $IMAGE_NAME:$TAG -f Dockerfile --push .

echo "Frontend image built and pushed as $IMAGE_NAME:$TAG"

# Update the deployment
cd ..
sed -i '' "s|image: .*|image: $IMAGE_NAME:$TAG|" k8s-public/frontend-deployment.yaml

echo "Updating Kubernetes deployment..."
kubectl apply -f k8s-public/frontend-deployment.yaml

echo "Waiting for deployment to roll out..."
kubectl rollout status deployment/frontend -n microservices

echo "Frontend deployment complete. Access the application at http://4.156.37.48/" 