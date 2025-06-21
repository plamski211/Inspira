#!/bin/bash

# Script to test the frontend deployment

echo "===== Testing Frontend Deployment ====="
echo ""

# Check if curl is installed
if ! command -v curl &> /dev/null; then
  echo "❌ curl not found. Please install it first."
  exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
  echo "⚠️ jq not found. Some tests will be limited."
fi

# Get the frontend URL
if [ -z "$1" ]; then
  # Try to get the URL from kubectl
  if command -v kubectl &> /dev/null; then
    FRONTEND_IP=$(kubectl get service frontend -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    if [ -n "$FRONTEND_IP" ]; then
      FRONTEND_URL="http://$FRONTEND_IP"
    else
      echo "❌ Could not determine frontend URL. Please provide it as an argument."
      echo "Usage: $0 <frontend-url>"
      exit 1
    fi
  else
    echo "❌ kubectl not found and no frontend URL provided."
    echo "Usage: $0 <frontend-url>"
    exit 1
  fi
else
  FRONTEND_URL=$1
fi

echo "Testing frontend at: $FRONTEND_URL"
echo ""

# Test 1: Check if the frontend is accessible
echo "Test 1: Checking if the frontend is accessible..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" $FRONTEND_URL)

if [ "$HTTP_STATUS" -eq 200 ]; then
  echo "✅ Frontend is accessible (HTTP 200)"
else
  echo "❌ Frontend is not accessible (HTTP $HTTP_STATUS)"
fi

# Test 2: Check if env-config.js is accessible
echo "Test 2: Checking if env-config.js is accessible..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" $FRONTEND_URL/env-config.js)

if [ "$HTTP_STATUS" -eq 200 ]; then
  echo "✅ env-config.js is accessible (HTTP 200)"
else
  echo "❌ env-config.js is not accessible (HTTP $HTTP_STATUS)"
fi

# Test 3: Check if env-config.js has the correct content
echo "Test 3: Checking if env-config.js has the correct content..."
ENV_CONFIG=$(curl -s $FRONTEND_URL/env-config.js)

if [[ "$ENV_CONFIG" == *"window.ENV"* ]]; then
  echo "✅ env-config.js has the correct content"
else
  echo "❌ env-config.js does not have the correct content"
  echo "Content: $ENV_CONFIG"
fi

# Test 4: Check if the health endpoint is accessible
echo "Test 4: Checking if the health endpoint is accessible..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" $FRONTEND_URL/health)

if [ "$HTTP_STATUS" -eq 200 ]; then
  echo "✅ Health endpoint is accessible (HTTP 200)"
else
  echo "❌ Health endpoint is not accessible (HTTP $HTTP_STATUS)"
fi

# Test 5: Check if the API is accessible
echo "Test 5: Checking if the API is accessible..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" $FRONTEND_URL/api/health 2>/dev/null)

if [ "$HTTP_STATUS" -eq 200 ]; then
  echo "✅ API is accessible (HTTP 200)"
else
  echo "❌ API is not accessible (HTTP $HTTP_STATUS)"
fi

echo ""
echo "===== Frontend Test Complete ====="
echo ""
echo "If any tests failed, check the following:"
echo "1. Make sure the frontend service is running"
echo "2. Check if the API Gateway is accessible from the frontend"
echo "3. Check the browser console for any errors"
echo ""
echo "You can fix the frontend deployment using the fix-frontend-deployment.sh script:"
echo "./scripts/deployment/fix-frontend-deployment.sh <resource-group> <aks-cluster> <registry>" 