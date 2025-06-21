#!/bin/bash

# Script to fix the frontend white screen issue in Azure

echo "===== Fixing Frontend White Screen Issue in Azure ====="
echo ""

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
  echo "❌ kubectl not found. Please install it first."
  exit 1
fi

# Create a ConfigMap for the frontend configuration
echo "Creating ConfigMap for frontend configuration..."
cat <<EOF > frontend-config.yaml
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

kubectl apply -f frontend-config.yaml
rm frontend-config.yaml

# Create a deployment file for the frontend
echo "Creating deployment file for frontend..."
cat <<EOF > frontend-azure-deployment.yaml
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
        image: pngbanks/frontend:latest
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
EOF

# Apply frontend deployment
echo "Applying frontend deployment..."
kubectl apply -f frontend-azure-deployment.yaml

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