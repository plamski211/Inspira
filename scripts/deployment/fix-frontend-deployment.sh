#!/bin/bash

# Complete script to fix the frontend deployment with the actual frontend application
set -e

echo "=== FIXING FRONTEND DEPLOYMENT ==="

# Variables
DOCKER_USERNAME=${1:-"pngbanks"}
TAG="fixed"
IMAGE_NAME="$DOCKER_USERNAME/frontend"

# Step 1: Update the Dockerfile to properly handle MIME types
echo "Step 1: Creating optimized Dockerfile..."
cd frontend

cat > Dockerfile.optimized << EOF
# Build stage
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Production stage
FROM nginx:alpine
WORKDIR /usr/share/nginx/html

# Copy built assets
COPY --from=builder /app/dist/ ./

# Create a special .htaccess-like file for MIME types
RUN echo '# Force MIME types for common file extensions' > ./mime-force.txt && \\
    echo 'application/javascript .js' >> ./mime-force.txt && \\
    echo 'text/css .css' >> ./mime-force.txt

# Configure Nginx
RUN echo 'server {\\n\
    listen 80;\\n\
    server_name _;\\n\
    root /usr/share/nginx/html;\\n\
    index index.html;\\n\
\\n\
    # Proper MIME type handling\\n\
    include /etc/nginx/mime.types;\\n\
    types {\\n\
        application/javascript js;\\n\
        text/css css;\\n\
    }\\n\
\\n\
    # Force Content-Type for specific files\\n\
    location ~* \\.js$ {\\n\
        default_type application/javascript;\\n\
        add_header Content-Type application/javascript;\\n\
    }\\n\
\\n\
    location ~* \\.css$ {\\n\
        default_type text/css;\\n\
        add_header Content-Type text/css;\\n\
    }\\n\
\\n\
    location / {\\n\
        try_files \$uri \$uri/ /index.html;\\n\
    }\\n\
\\n\
    location /api/ {\\n\
        proxy_pass http://api-gateway;\\n\
        proxy_http_version 1.1;\\n\
        proxy_set_header Upgrade \$http_upgrade;\\n\
        proxy_set_header Connection "upgrade";\\n\
        proxy_set_header Host \$host;\\n\
    }\\n\
}' > /etc/nginx/conf.d/default.conf

# Create env-config.js
RUN echo 'window.ENV = {\\n\
  API_URL: "/api",\\n\
  AUTH0_DOMAIN: "dev-i9j8l4xe.us.auth0.com",\\n\
  AUTH0_CLIENT_ID: "JBfJJE07F7yrWTPq7nZ04WO4XdqzPvOa",\\n\
  AUTH0_AUDIENCE: "https://api.inspira.com",\\n\
  AUTH0_REDIRECT_URI: window.location.origin,\\n\
  ENV: "production"\\n\
};\\n\
console.log("Environment config loaded:", window.ENV);' > ./env-config.js

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

# Step 2: Build and push the Docker image
echo "Step 2: Building and pushing Docker image..."
docker build -t $IMAGE_NAME:$TAG -f Dockerfile.optimized .
docker push $IMAGE_NAME:$TAG

cd ..

# Step 3: Create a deployment manifest for the fixed frontend
echo "Step 3: Creating deployment manifest..."
cat > frontend-fixed-deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: microservices
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
        image: $IMAGE_NAME:$TAG
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 50m
            memory: 64Mi
          limits:
            cpu: 100m
            memory: 128Mi
---
apiVersion: v1
kind: Service
metadata:
  name: frontend
  namespace: microservices
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF

# Step 4: Apply the deployment
echo "Step 4: Applying deployment..."
kubectl apply -f frontend-fixed-deployment.yaml

# Step 5: Update the ingress to use the frontend service
echo "Step 5: Updating ingress..."
kubectl patch ingress inspira-ingress -n microservices --type=json -p='[{"op": "replace", "path": "/spec/rules/0/http/paths/4/backend/service/name", "value": "frontend"}]'

# Step 6: Wait for the deployment to complete
echo "Step 6: Waiting for deployment to complete..."
kubectl rollout status deployment/frontend -n microservices

echo "=== FRONTEND DEPLOYMENT FIXED ==="
echo "Your actual frontend application should now be accessible at http://4.156.37.48"

# Verify the deployment
kubectl get pods -n microservices -l app=frontend 