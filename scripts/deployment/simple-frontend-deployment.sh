#!/bin/bash
# simple-frontend-deployment.sh - Deploy just the frontend container with a simple approach

set -e

echo "===== Building and deploying the frontend only ====="

# Set up the working directory
cd frontend

# Create env-config.js
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
  BUILD_TIME: '$(date)',
  ENV: 'development'
};
console.log('Environment config loaded:', window.ENV);
EOF

# Create a simple nginx.conf without problematic directives
echo "Creating simplified NGINX configuration..."
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
}
EOF

# Create a simplified Dockerfile 
echo "Creating simplified Dockerfile..."
cat > Dockerfile.simple << EOF
FROM node:18-alpine AS builder
WORKDIR /app

# Copy source code
COPY . .

# Install dependencies
RUN npm ci

# Build the application
RUN npm run build

# Production stage
FROM nginx:alpine
WORKDIR /usr/share/nginx/html

# Copy built assets
COPY --from=builder /app/dist .

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy env-config.js
COPY --from=builder /app/public/env-config.js ./env-config.js

# Expose port 80
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
EOF

# Build the frontend
echo "Building frontend..."
npm ci
npm run build

# Stop and remove any existing frontend container
echo "Removing any existing frontend container..."
docker rm -f inspira-frontend 2>/dev/null || true

# Build and run the frontend container
echo "Building and starting frontend container..."
docker build -t inspira-frontend:latest -f Dockerfile.simple .
docker run -d --name inspira-frontend -p 8080:80 inspira-frontend:latest

echo "===== Frontend Deployment Complete! ====="
echo "Frontend URL: http://localhost:8080"
echo "Check container logs with: docker logs inspira-frontend" 