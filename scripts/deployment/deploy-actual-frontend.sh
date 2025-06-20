#!/bin/bash

# This script deploys your actual frontend application to Kubernetes
set -e

echo "=== Deploying actual frontend application ==="

# Set variables
DOCKER_HUB_USERNAME=${1:-"pngbanks"}
IMAGE_NAME="$DOCKER_HUB_USERNAME/frontend"
TAG="actual"

echo "Building the frontend from source code..."

# Navigate to frontend directory
cd frontend

# Create env-config.js
echo "Creating environment configuration..."
mkdir -p public
cat > public/env-config.js << EOF
// Environment configuration for frontend
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

# Create a Dockerfile that directly uses the files from the build
cat > Dockerfile.direct << EOF
# Build stage
FROM node:18-alpine AS builder
WORKDIR /app
COPY . .
RUN npm ci
RUN npm run build

# Production stage
FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY --from=builder /app/public/env-config.js /usr/share/nginx/html/env-config.js

# Create a proper NGINX configuration
RUN echo 'server {\\n\
    listen 80;\\n\
    server_name _;\\n\
    root /usr/share/nginx/html;\\n\
    index index.html;\\n\
\\n\
    # MIME types\\n\
    include /etc/nginx/mime.types;\\n\
\\n\
    # Additional MIME type declarations\\n\
    types {\\n\
        application/javascript js;\\n\
        text/css css;\\n\
    }\\n\
\\n\
    # Serve static files\\n\
    location / {\\n\
        try_files \$uri \$uri/ /index.html;\\n\
        add_header "Access-Control-Allow-Origin" "*";\\n\
    }\\n\
\\n\
    # JavaScript files - explicitly set content type\\n\
    location ~* \\.js\$ {\\n\
        add_header Content-Type "application/javascript";\\n\
        try_files \$uri =404;\\n\
    }\\n\
\\n\
    # CSS files - explicitly set content type\\n\
    location ~* \\.css\$ {\\n\
        add_header Content-Type "text/css";\\n\
        try_files \$uri =404;\\n\
    }\\n\
\\n\
    # Handle API requests\\n\
    location /api/ {\\n\
        proxy_pass http://api-gateway;\\n\
        proxy_http_version 1.1;\\n\
        proxy_set_header Upgrade \$http_upgrade;\\n\
        proxy_set_header Connection "upgrade";\\n\
        proxy_set_header Host \$host;\\n\
        proxy_cache_bypass \$http_upgrade;\\n\
    }\\n\
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

# Build and push the Docker image
echo "Building Docker image..."
docker build -t $IMAGE_NAME:$TAG -f Dockerfile.direct .
docker push $IMAGE_NAME:$TAG

# Go back to the project root
cd ..

# Update the frontend deployment to use our actual frontend
echo "Updating frontend deployment..."
kubectl set image deployment/frontend -n microservices frontend=$IMAGE_NAME:$TAG

# Wait for the deployment to complete
echo "Waiting for deployment to complete..."
kubectl rollout status deployment/frontend -n microservices

echo "=== Frontend deployment completed ==="
echo "Your actual frontend should now be accessible at http://4.156.37.48"

# Check the status
kubectl get pods -n microservices -l app=frontend 