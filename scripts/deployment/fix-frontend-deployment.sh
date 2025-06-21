#!/bin/bash

# Script to fix the frontend deployment in Azure

echo "===== Fixing Frontend Deployment in Azure ====="
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
REGISTRY=${3:-"inspiraregistry"}
SECRET_NAME="acr-auth"

echo "Resource Group: $RESOURCE_GROUP"
echo "AKS Cluster: $AKS_CLUSTER"
echo "Registry: $REGISTRY"
echo "Secret Name: $SECRET_NAME"

# Get AKS credentials
echo "Getting AKS credentials..."
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER --overwrite-existing

# Check if frontend directory exists
if [ ! -d "frontend" ]; then
  echo "❌ Frontend directory not found"
  exit 1
fi

# Create ACR authentication secret
echo "Creating ACR authentication secret..."
./scripts/deployment/create-acr-secret.sh $REGISTRY $SECRET_NAME

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

# Build frontend Docker image
echo "Building frontend Docker image..."
docker build -t $REGISTRY.azurecr.io/frontend:latest frontend/

# Log in to Azure Container Registry
echo "Logging in to Azure Container Registry..."
az acr login --name $REGISTRY

# Push frontend Docker image
echo "Pushing frontend Docker image..."
docker push $REGISTRY.azurecr.io/frontend:latest

# Create frontend deployment YAML
echo "Creating frontend deployment YAML..."
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
      imagePullSecrets:
      - name: $SECRET_NAME
      containers:
      - name: frontend
        image: $REGISTRY.azurecr.io/frontend:latest
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
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
        volumeMounts:
        - name: env-config
          mountPath: /usr/share/nginx/html/env-config.js
          subPath: env-config.js
      volumes:
      - name: env-config
        configMap:
          name: frontend-config
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
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: frontend-config
  namespace: default
data:
  env-config.js: |
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

# Apply frontend deployment
echo "Applying frontend deployment..."
kubectl apply -f frontend-deployment.yaml

# Delete any existing pods to force a new deployment
echo "Deleting existing frontend pods to force a new deployment..."
kubectl delete pods -l app=frontend --grace-period=0 --force || true

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
echo ""
echo "You can also run the check-frontend.sh script to diagnose any issues:"
echo "./scripts/deployment/check-frontend.sh" 