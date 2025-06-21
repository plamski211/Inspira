#!/bin/bash

# Script to check the frontend deployment in Azure

echo "===== Checking Frontend Deployment ====="
echo ""

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
  echo "❌ kubectl not found. Please install it first."
  exit 1
fi

# Check if curl is installed
if ! command -v curl &> /dev/null; then
  echo "❌ curl not found. Please install it first."
  exit 1
fi

# Get the frontend service IP
FRONTEND_IP=$(kubectl get service frontend -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)

if [ -z "$FRONTEND_IP" ]; then
  echo "❌ Frontend service not found or does not have an external IP"
  echo "Check if the frontend service is deployed:"
  kubectl get service frontend
  exit 1
fi

echo "Frontend IP: $FRONTEND_IP"
echo ""

# Check if the frontend is accessible
echo "Checking if frontend is accessible..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$FRONTEND_IP)

if [ "$HTTP_STATUS" -eq 200 ]; then
  echo "✅ Frontend is accessible (HTTP 200)"
else
  echo "❌ Frontend is not accessible (HTTP $HTTP_STATUS)"
fi

# Check if env-config.js is accessible
echo "Checking if env-config.js is accessible..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$FRONTEND_IP/env-config.js)

if [ "$HTTP_STATUS" -eq 200 ]; then
  echo "✅ env-config.js is accessible (HTTP 200)"
else
  echo "❌ env-config.js is not accessible (HTTP $HTTP_STATUS)"
fi

# Check frontend logs
echo ""
echo "Frontend logs:"
kubectl logs deployment/frontend --tail=50

echo ""
echo "===== Frontend Check Complete ====="
echo ""
echo "If you're seeing a white screen, here are some possible fixes:"
echo ""
echo "1. Check if the frontend is correctly built:"
echo "   - Rebuild the frontend with: docker build -t frontend:latest frontend/"
echo "   - Redeploy with: kubectl rollout restart deployment/frontend"
echo ""
echo "2. Check if the API Gateway is accessible from the frontend:"
echo "   - Make sure the API Gateway service is running: kubectl get service api-gateway"
echo "   - Check if the API Gateway is accessible from within the cluster"
echo ""
echo "3. Check browser console for JavaScript errors:"
echo "   - Open the browser developer tools (F12) and check the console"
echo "   - Look for network errors or JavaScript exceptions"
echo ""
echo "4. Update the frontend configuration:"
echo "   - Edit frontend/public/env-config.js with the correct API URL"
echo "   - Rebuild and redeploy the frontend" 