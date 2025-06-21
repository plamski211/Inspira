#!/bin/bash

# Script to deploy the frontend to Azure

echo "===== Frontend Deployment to Azure ====="
echo ""

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
  echo "❌ kubectl not found. Please install it first."
  exit 1
fi

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
  echo "❌ Azure CLI not found. Please install it first."
  exit 1
fi

# Check if logged in to Azure
echo "Checking Azure login status..."
if ! az account show &> /dev/null; then
  echo "You need to log in to Azure first:"
  az login
else
  echo "✅ Already logged in to Azure"
fi

# Set variables
RESOURCE_GROUP=${1:-"inspira-resources"}
AKS_CLUSTER=${2:-"inspira-cluster"}

echo "Resource Group: $RESOURCE_GROUP"
echo "AKS Cluster: $AKS_CLUSTER"

# Get AKS credentials
echo "Getting AKS credentials..."
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER --overwrite-existing

# Check if frontend directory exists
if [ ! -d "frontend" ]; then
  echo "❌ Frontend directory not found"
  exit 1
fi

# Rebuild frontend Docker image
echo "Building frontend Docker image..."
docker build -t frontend:latest frontend/

# Create a temporary deployment file
echo "Creating deployment file..."
cat > frontend-deployment.yaml << EOF
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
        image: frontend:latest
        imagePullPolicy: IfNotPresent
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
          initialDelaySeconds: 30
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

# Apply the deployment
echo "Applying deployment..."
kubectl apply -f frontend-deployment.yaml

# Wait for the deployment to be ready
echo "Waiting for deployment to be ready..."
kubectl rollout status deployment/frontend

# Get the external IP
echo "Getting external IP..."
EXTERNAL_IP=""
while [ -z "$EXTERNAL_IP" ]; do
  echo "Waiting for external IP..."
  EXTERNAL_IP=$(kubectl get service frontend -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
  if [ -z "$EXTERNAL_IP" ]; then
    sleep 10
  fi
done

echo ""
echo "===== Frontend Deployment Complete ====="
echo ""
echo "Frontend is available at: http://$EXTERNAL_IP"
echo ""
echo "If you see a white screen, check the following:"
echo "1. Check the frontend logs: kubectl logs deployment/frontend"
echo "2. Check if the API Gateway is accessible from the frontend"
echo "3. Check if the frontend is correctly configured to access the API Gateway"
echo ""
echo "To fix the white screen issue, you can try:"
echo "1. Update the API Gateway URL in the frontend configuration"
echo "2. Rebuild and redeploy the frontend with the correct configuration"
echo "3. Check the browser console for any errors" 