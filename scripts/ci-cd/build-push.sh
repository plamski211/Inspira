#!/bin/bash
# build-push.sh

# Set variables
ACR_NAME=$(echo $ACR_NAME)
TAG=$(date +%Y%m%d%H%M)

# Login to ACR
az acr login --name $ACR_NAME

# Build and push each service
for SERVICE in api-gateway user-service content-service media-service frontend; do
  echo "Building $SERVICE..."
  docker build -t ${ACR_NAME}.azurecr.io/${SERVICE}:${TAG} -t ${ACR_NAME}.azurecr.io/${SERVICE}:latest ./${SERVICE}
  
  echo "Pushing $SERVICE..."
  docker push ${ACR_NAME}.azurecr.io/${SERVICE}:${TAG}
  docker push ${ACR_NAME}.azurecr.io/${SERVICE}:latest
done

echo "All images built and pushed with tag: $TAG"
echo $TAG > current-tag.txt 