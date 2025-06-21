#!/bin/bash

# Script to fix the frontend deployment using a public Docker Hub image

echo "===== Fixing Frontend Deployment with Public Image ====="
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
DOCKER_USERNAME=${1:-"nginx"}
IMAGE_NAME=${2:-"nginx"}
IMAGE_TAG=${3:-"alpine"}

echo "Docker Username: $DOCKER_USERNAME"
echo "Image Name: $IMAGE_NAME"
echo "Image Tag: $IMAGE_TAG"

# Create frontend deployment YAML
echo "Creating frontend deployment YAML..."
cat > frontend-public-deployment.yaml << EOF
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
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
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
kubectl apply -f frontend-public-deployment.yaml

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
echo "This is a temporary solution using a public Nginx image."
echo "Once you can access this page, you can proceed with deploying your actual frontend." 