#!/bin/bash

# Script to fix the frontend deployment using Docker Hub

echo "===== Fixing Frontend Deployment with Docker Hub ====="
echo ""

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
  echo "❌ kubectl not found. Please install it first."
  exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
  echo "❌ Docker not found. Please install it first."
  exit 1
fi

# Set variables
DOCKER_USERNAME=${1:-"your-dockerhub-username"}
IMAGE_NAME=${2:-"inspira-frontend"}
IMAGE_TAG=${3:-"latest"}

if [ "$DOCKER_USERNAME" = "your-dockerhub-username" ]; then
  echo "Please provide your Docker Hub username:"
  read -r DOCKER_USERNAME
fi

echo "Docker Username: $DOCKER_USERNAME"
echo "Image Name: $IMAGE_NAME"
echo "Image Tag: $IMAGE_TAG"

# Check if frontend directory exists
if [ ! -d "frontend" ]; then
  echo "❌ Frontend directory not found"
  exit 1
fi

# Create env-config.js if it doesn't exist
if [ ! -f "frontend/public/env-config.js" ]; then
  echo "Creating env-config.js..."
  mkdir -p frontend/public
  cat > frontend/public/env-config.js << EOF
// Environment configuration
window.ENV = {
  API_URL: '/api',
  AUTH0_DOMAIN: 'dev-i9j8l4xe.us.auth0.com',
  AUTH0_CLIENT_ID: 'JBfJJE07F7yrWTPq7nZ04WO4XdqzPvOa',
  AUTH0_AUDIENCE: 'https://api.inspira.com',
  AUTH0_REDIRECT_URI: window.location.origin,
  ENV: 'production'
};
console.log('Environment config loaded:', window.ENV);
EOF
fi

# Check if index.html exists
if [ ! -f "frontend/public/index.html" ]; then
  echo "Creating index.html..."
  mkdir -p frontend/public
  cat > frontend/public/index.html << EOF
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Inspira Platform</title>
  <script src="/env-config.js"></script>
  <style>
    body {
      font-family: Arial, sans-serif;
      margin: 0;
      padding: 20px;
      background-color: #f5f5f5;
    }
    .container {
      max-width: 800px;
      margin: 0 auto;
      background-color: white;
      padding: 20px;
      border-radius: 8px;
      box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
    }
    h1 {
      color: #333;
    }
    .service {
      margin-bottom: 20px;
      padding: 10px;
      border: 1px solid #ddd;
      border-radius: 4px;
    }
    .service h2 {
      margin-top: 0;
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>Inspira Platform</h1>
    <p>Welcome to the Inspira microservices platform.</p>
    
    <div class="service">
      <h2>Frontend</h2>
      <p>This is the frontend service that provides the user interface.</p>
    </div>
    
    <div class="service">
      <h2>API Gateway</h2>
      <p>Routes requests to the appropriate microservices.</p>
    </div>
    
    <div class="service">
      <h2>User Service</h2>
      <p>Manages user accounts and authentication.</p>
    </div>
    
    <div class="service">
      <h2>Content Service</h2>
      <p>Handles content storage and retrieval.</p>
    </div>
    
    <div class="service">
      <h2>Media Service</h2>
      <p>Processes and stores media files.</p>
    </div>
  </div>

  <script>
    console.log('Frontend loaded successfully');
  </script>
</body>
</html>
EOF
fi

# Log in to Docker Hub
echo "Logging in to Docker Hub..."
docker login -u $DOCKER_USERNAME

# Build frontend Docker image
echo "Building frontend Docker image..."
docker build -t $DOCKER_USERNAME/$IMAGE_NAME:$IMAGE_TAG -f frontend/Dockerfile.simple frontend/

# Push frontend Docker image
echo "Pushing frontend Docker image..."
docker push $DOCKER_USERNAME/$IMAGE_NAME:$IMAGE_TAG

# Create frontend deployment YAML
echo "Creating frontend deployment YAML..."
cat > frontend-dockerhub-deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: default
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
        image: $DOCKER_USERNAME/$IMAGE_NAME:$IMAGE_TAG
        imagePullPolicy: Always
        ports:
        - containerPort: 80
        resources:
          limits:
            cpu: "0.5"
            memory: "512Mi"
          requests:
            cpu: "0.2"
            memory: "256Mi"
        livenessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: frontend
  namespace: default
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
  type: LoadBalancer
EOF

# Delete existing deployment
echo "Deleting existing frontend deployment..."
kubectl delete deployment frontend --grace-period=0 --force || true
kubectl delete service frontend || true
kubectl delete configmap frontend-config || true

# Wait for resources to be deleted
echo "Waiting for resources to be deleted..."
sleep 5

# Apply frontend deployment
echo "Applying frontend deployment..."
kubectl apply -f frontend-dockerhub-deployment.yaml

# Wait for frontend deployment to be ready
echo "Waiting for frontend deployment to be ready..."
kubectl rollout status deployment/frontend

# Get frontend service IP
echo "Getting frontend service IP..."
FRONTEND_IP=""
while [ -z "$FRONTEND_IP" ]; do
  echo "Waiting for frontend service IP..."
  FRONTEND_IP=$(kubectl get service frontend -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
  if [ -z "$FRONTEND_IP" ]; then
    sleep 10
  fi
done

echo ""
echo "===== Frontend Deployment Fixed ====="
echo ""
echo "Frontend is available at: http://$FRONTEND_IP"
echo ""
echo "If you still see a white screen, check the following:"
echo "1. Check the frontend logs: kubectl logs deployment/frontend"
echo "2. Check if the API Gateway is accessible from the frontend"
echo "3. Check the browser console for any errors" 