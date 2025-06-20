#!/bin/bash

# Script to build and push the production frontend image
# Usage: ./build-frontend-prod.sh [docker-hub-username]

set -e

# Configuration
DOCKER_HUB_USERNAME=${1:-"pngbanks"}
IMAGE_NAME="$DOCKER_HUB_USERNAME/frontend"
TAG="prod"

echo "Building frontend image for Kubernetes deployment..."

# Navigate to frontend directory
cd frontend

# Create env-config.js for production
echo "Creating environment configuration..."
mkdir -p public
cat > public/env-config.js << EOF
// This file is generated at build time and injected into the static HTML
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

# Create optimized nginx.conf
echo "Creating optimized NGINX configuration..."
cat > nginx.conf << EOF
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;
    
    # Serve static files
    location / {
        try_files \$uri \$uri/ /index.html;
        add_header 'Access-Control-Allow-Origin' '*';
    }
    
    # Serve JavaScript files with correct MIME type
    location ~* \.js$ {
        add_header Content-Type application/javascript;
        try_files \$uri =404;
    }
    
    # Serve CSS files with correct MIME type
    location ~* \.css$ {
        add_header Content-Type text/css;
        try_files \$uri =404;
    }
    
    # Serve asset files
    location /assets/ {
        try_files \$uri =404;
    }

    # Handle API requests
    location /api/ {
        proxy_pass http://api-gateway;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Build the frontend
echo "Building React app..."
npm ci
npm run build

# Create production Dockerfile
cat > Dockerfile.prod << EOF
FROM nginx:alpine
WORKDIR /usr/share/nginx/html

# Copy built assets
COPY dist/ .

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy env-config.js
COPY public/env-config.js ./env-config.js

# Expose port 80
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
EOF

# Build and push the Docker image
echo "Building and pushing Docker image..."
docker build -t $IMAGE_NAME:$TAG -f Dockerfile.prod .

# Authenticate with Docker Hub
echo "Logging in to Docker Hub..."
docker push $IMAGE_NAME:$TAG

echo "Frontend image built and pushed as $IMAGE_NAME:$TAG"

# Go back to the project root
cd ..

# Update the frontend deployment YAML
echo "Updating frontend deployment YAML..."
sed -i '' "s|image: .*|image: $IMAGE_NAME:$TAG|" frontend-new-deployment.yaml

echo "Frontend build and push complete."

# Apply the Kubernetes configurations
echo "Applying Kubernetes configurations..."
kubectl apply -f frontend-new-deployment.yaml
kubectl apply -f fixed-ingress.yaml

echo "Waiting for deployment to roll out..."
kubectl rollout status deployment/frontend -n microservices

echo "Frontend deployment complete."
echo "You can access the application at your ingress IP address." 