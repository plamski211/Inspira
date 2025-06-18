#!/bin/bash

# Script to build and push a multi-platform frontend image
# Usage: ./build-multiplatform-frontend.sh <docker-hub-username>

set -e

# Configuration
REGISTRY="pngbanks"
IMAGE_NAME="${REGISTRY}/frontend"
TAG="latest"
PLATFORMS="linux/amd64,linux/arm64"

echo "Building multi-platform frontend image..."

# Navigate to frontend directory
cd frontend

# Make sure nginx.conf exists
if [ ! -f nginx.conf ]; then
  echo "Creating nginx.conf..."
  cat > nginx.conf << EOF
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    # Handle OPTIONS requests
    if (\$request_method = 'OPTIONS') {
        add_header 'Access-Control-Allow-Origin' '*';
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, PUT, DELETE';
        add_header 'Access-Control-Allow-Headers' 'X-Requested-With, Content-Type, Authorization';
        add_header 'Access-Control-Max-Age' 1728000;
        add_header 'Content-Type' 'text/plain charset=UTF-8';
        add_header 'Content-Length' 0;
        return 204;
    }

    # Serve static files
    location / {
        try_files \$uri \$uri/ /index.html;
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, PUT, DELETE' always;
        add_header 'Access-Control-Allow-Headers' 'X-Requested-With, Content-Type, Authorization' always;
    }

    # Proxy API requests
    location /api/ {
        proxy_pass http://api-gateway;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Disable caching for index.html
    location ~ ^/(index\.html)$ {
        expires -1;
        add_header Cache-Control 'no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0';
    }
}
EOF
fi

# Create a buildx builder if it doesn't exist
docker buildx create --use --name multi-platform-builder || true

# Build the multi-platform image
echo "Building and pushing multi-platform image..."
docker buildx build \
  --platform ${PLATFORMS} \
  --tag ${IMAGE_NAME}:${TAG} \
  --file Dockerfile.fixed \
  --push \
  .

echo "Multi-platform image built and pushed as ${IMAGE_NAME}:${TAG}"

# Go back to the root directory
cd ..

# Create Kubernetes deployment file
echo "Creating Kubernetes deployment file..."
cat > k8s-public/frontend-multiplatform.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: microservices
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: ${IMAGE_NAME}:${TAG}
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: frontend
  namespace: microservices
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF

echo "Created k8s-public/frontend-multiplatform.yaml"
echo "To deploy, run: kubectl apply -f k8s-public/frontend-multiplatform.yaml" 