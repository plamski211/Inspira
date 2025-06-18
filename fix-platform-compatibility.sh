#!/bin/bash
# fix-platform-compatibility.sh - Script to rebuild images with correct platform compatibility

set -e

ACR_NAME=inspiraregistry20250617
PLATFORM="linux/amd64"

# Enable Docker BuildKit
export DOCKER_BUILDX_NO_DEFAULT_ATTESTATIONS=1
export DOCKER_BUILDKIT=1

echo "Setting up Docker buildx for multi-platform builds..."
docker buildx create --name inspira-builder --use || true
docker buildx inspect --bootstrap

# Rebuild and push each service image with platform compatibility
for SERVICE in api-gateway user-service frontend; do
  if [ -d "$SERVICE" ]; then
    echo "Rebuilding $SERVICE for platform $PLATFORM..."
    
    cd $SERVICE
    
    # Build and push directly to ACR
    echo "Building and pushing $SERVICE to ACR..."
    docker buildx build --platform $PLATFORM \
      -t $ACR_NAME.azurecr.io/$SERVICE:latest \
      --push \
      .
    
    cd ..
    
    echo "$SERVICE rebuilt and pushed to ACR"
  else
    echo "Directory $SERVICE not found, skipping..."
  fi
done

# Build a simple test image
echo "Building test image..."
mkdir -p test
cat > test/Dockerfile << EOF
FROM nginx:alpine
RUN echo "Inspira Test Image" > /usr/share/nginx/html/index.html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

cd test
docker buildx build --platform $PLATFORM \
  -t $ACR_NAME.azurecr.io/test:latest \
  --push \
  .
cd ..

echo "All images rebuilt with platform compatibility: $PLATFORM"
echo "You can now restart your deployments with: kubectl rollout restart deployment -n microservices" 