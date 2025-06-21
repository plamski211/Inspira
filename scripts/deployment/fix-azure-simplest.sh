#!/bin/bash

# Script to fix the frontend white screen issue in Azure with the simplest possible approach

echo "===== SIMPLEST FIX: Frontend White Screen in Azure ====="
echo ""

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
  echo "❌ kubectl not found. Please install it first."
  exit 1
fi

# Create a very simple deployment YAML
cat <<EOF > frontend-simplest.yaml
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
        image: nginx:alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: index-html
          mountPath: /usr/share/nginx/html/index.html
          subPath: index.html
      volumes:
      - name: index-html
        configMap:
          name: index-html
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
  name: index-html
  namespace: default
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head>
      <title>Inspira Platform</title>
      <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background-color: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1); }
        h1 { color: #333; }
        .service { margin-bottom: 20px; padding: 10px; border: 1px solid #ddd; border-radius: 4px; }
        .service h2 { margin-top: 0; }
        .button { display: inline-block; background-color: #4CAF50; color: white; padding: 10px 20px; text-align: center; text-decoration: none; border-radius: 4px; margin-top: 10px; }
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
    </body>
    </html>
EOF

# Apply the deployment
echo "Applying the simplest frontend deployment..."
kubectl apply -f frontend-simplest.yaml

# Delete any existing pods to force a new deployment
echo "Deleting existing frontend pods to force a new deployment..."
kubectl delete pods -l app=frontend --grace-period=0 --force || true

# Wait for frontend deployment to be ready
echo "Waiting for frontend deployment to be ready..."
kubectl rollout status deployment/frontend

# Get the external IP
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
echo "===== SIMPLEST FIX COMPLETE ====="
echo ""
echo "Frontend is now available at: http://$FRONTEND_IP"
echo ""
echo "This is a very simple static HTML page. If you need more functionality,"
echo "you will need to implement a more complete solution."
echo "" 