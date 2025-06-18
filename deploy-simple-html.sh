#!/bin/bash
set -e

# Configuration
IMAGE_NAME="pngbanks/frontend"
TAG="simple-html"
PLATFORMS="linux/amd64,linux/arm64"

echo "Building simple HTML frontend image..."

# Navigate to frontend directory
cd frontend

# Create a buildx builder if it doesn't exist
docker buildx create --use --name multi-platform-builder || true

# Build the multi-platform image
docker buildx build \
  --platform $PLATFORMS \
  --tag $IMAGE_NAME:$TAG \
  --file Dockerfile.simple-html \
  --push \
  .

echo "Simple HTML frontend image built and pushed as $IMAGE_NAME:$TAG"

# Update the deployment YAML
cd ..
cat > k8s-public/frontend-simple-html.yaml << EOF
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
        image: $IMAGE_NAME:$TAG
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

echo "Created k8s-public/frontend-simple-html.yaml with the simple HTML image"
echo "Applying the deployment..."
kubectl apply -f k8s-public/frontend-simple-html.yaml

echo "Waiting for deployment to roll out..."
kubectl rollout status deployment/frontend -n microservices

echo "Frontend deployment complete. Access the application at http://4.156.37.48/" 