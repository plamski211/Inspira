#!/bin/bash
# deploy-complete-frontend.sh - Complete script to deploy the React frontend

set -e

echo "===== Starting complete frontend deployment process ====="

# 1. Create environment configuration
echo "Creating environment configuration..."
../configuration/create-env-config.sh

# 2. Deploy the React frontend
echo "Deploying React frontend..."
./deploy-react-frontend.sh

# 3. Check the deployment
echo "Checking deployment status..."
kubectl get pods -n microservices | grep frontend
kubectl get services -n microservices | grep frontend

echo "===== Frontend deployment process complete ====="
echo "Your React frontend should now be properly deployed to Azure."
echo "If you're still seeing the placeholder, wait a few minutes for DNS propagation and clear your browser cache."
echo ""
echo "You can access your frontend through the ingress at: http://4.156.37.48/" 