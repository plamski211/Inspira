#!/bin/bash

# Script to fix the frontend white screen issue in Docker Compose

echo "===== Fixing Frontend White Screen Issue in Docker Compose ====="
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
  echo "❌ Docker not found. Please install it first."
  exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
  echo "❌ Docker Compose not found. Please install it first."
  exit 1
fi

# Create env-config.js
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
  ENV: 'development'
};
console.log('Environment config loaded:', window.ENV);
EOF

# Stop the frontend container
echo "Stopping the frontend container..."
docker-compose stop frontend

# Remove the frontend container
echo "Removing the frontend container..."
docker-compose rm -f frontend

# Rebuild the frontend container
echo "Rebuilding the frontend container..."
docker-compose build frontend

# Start the frontend container
echo "Starting the frontend container..."
docker-compose up -d frontend

echo ""
echo "===== Frontend Fix Complete ====="
echo ""
echo "The frontend should now be accessible at: http://localhost"
echo ""
echo "If you still see a white screen, try the following:"
echo "1. Clear your browser cache"
echo "2. Check the frontend logs: docker-compose logs frontend"
echo "3. Make sure the API Gateway is running: docker-compose ps api-gateway"
echo "4. Check if the API Gateway is accessible: curl http://localhost:8000/health"
echo "" 