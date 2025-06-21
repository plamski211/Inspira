#!/bin/bash

# Script to properly deploy the React frontend to Azure

echo "===== PROPER FIX: Frontend White Screen in Azure ====="
echo ""

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
  echo "❌ kubectl not found. Please install it first."
  exit 1
fi

# Create a temporary directory for building
TEMP_DIR=$(mktemp -d)
echo "Creating temporary build directory: $TEMP_DIR"

# Copy the frontend files to the temporary directory
echo "Copying frontend files..."
cp -r frontend/* $TEMP_DIR/

# Create a proper Dockerfile for production
cat <<EOF > $TEMP_DIR/Dockerfile.azure
# Build stage
FROM node:18-alpine as build

WORKDIR /app

# Copy package files and install dependencies
COPY package.json package-lock.json ./
RUN npm ci

# Copy the rest of the application code
COPY . .

# Build the application
RUN npm run build

# Production stage
FROM nginx:alpine

# Copy the build output to replace the default nginx contents
COPY --from=build /app/dist /usr/share/nginx/html

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Create a simple health check endpoint
RUN mkdir -p /usr/share/nginx/html/health && \
    echo "OK" > /usr/share/nginx/html/health/index.html

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
EOF

# Create a proper nginx.conf file
cat <<EOF > $TEMP_DIR/nginx.conf
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    # MIME types
    include /etc/nginx/mime.types;
    types {
        application/javascript js;
        text/css css;
    }

    # Health check endpoint
    location /health {
        access_log off;
        add_header Content-Type text/plain;
        return 200 'OK';
    }

    # API forwarding
    location /api/ {
        proxy_pass http://api-gateway:8080/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    # React app - serve index.html for any path
    location / {
        try_files \$uri \$uri/ /index.html;
        add_header Cache-Control "no-store, no-cache, must-revalidate";
    }

    # Static assets caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 30d;
        add_header Cache-Control "public, max-age=2592000";
        access_log off;
    }

    # Error handling
    error_page 404 /index.html;
    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }
}
EOF

# Create a script to build and push the Docker image
cat <<EOF > $TEMP_DIR/build-push.sh
#!/bin/bash
set -e

# Build the Docker image
docker build -t inspira-frontend:azure -f Dockerfile.azure .

# Tag the image for Azure Container Registry
docker tag inspira-frontend:azure myacr.azurecr.io/inspira-frontend:latest

# Push the image to Azure Container Registry
docker push myacr.azurecr.io/inspira-frontend:latest
EOF
chmod +x $TEMP_DIR/build-push.sh

# Create Kubernetes deployment files
cat <<EOF > $TEMP_DIR/frontend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: default
spec:
  replicas: 2
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
        image: myacr.azurecr.io/inspira-frontend:latest
        ports:
        - containerPort: 80
        livenessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
        resources:
          limits:
            cpu: "0.5"
            memory: "512Mi"
          requests:
            cpu: "0.2"
            memory: "256Mi"
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

echo "Temporary build directory created at: $TEMP_DIR"
echo ""
echo "To deploy your frontend to Azure, follow these steps:"
echo ""
echo "1. Navigate to the temporary directory:"
echo "   cd $TEMP_DIR"
echo ""
echo "2. Build and push the Docker image (you may need to modify the ACR name):"
echo "   ./build-push.sh"
echo ""
echo "3. Deploy to Kubernetes:"
echo "   kubectl apply -f frontend-deployment.yaml"
echo ""
echo "4. Wait for the deployment to complete:"
echo "   kubectl rollout status deployment/frontend"
echo ""
echo "5. Get the external IP:"
echo "   kubectl get service frontend -o jsonpath='{.status.loadBalancer.ingress[0].ip}'"
echo ""
echo "===== PROPER FIX INSTRUCTIONS COMPLETE ====="
echo ""
echo "Would you like to proceed with the build and deployment now? (y/n)"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  echo "Proceeding with build and deployment..."
  cd $TEMP_DIR
  
  # Modify ACR name based on your Azure setup
  echo "Please enter your Azure Container Registry name (e.g., myacr):"
  read -r acr_name
  
  # Update the ACR name in the files
  sed -i.bak "s/myacr.azurecr.io/${acr_name}.azurecr.io/g" build-push.sh frontend-deployment.yaml
  
  # Build and push the Docker image
  echo "Building and pushing the Docker image..."
  ./build-push.sh
  
  # Deploy to Kubernetes
  echo "Deploying to Kubernetes..."
  kubectl apply -f frontend-deployment.yaml
  
  # Wait for the deployment to complete
  echo "Waiting for deployment to complete..."
  kubectl rollout status deployment/frontend
  
  # Get the external IP
  echo "Getting external IP..."
  FRONTEND_IP=$(kubectl get service frontend -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  
  echo ""
  echo "===== DEPLOYMENT COMPLETE ====="
  echo ""
  echo "Frontend is now available at: http://$FRONTEND_IP"
else
  echo "Deployment skipped. You can deploy manually using the instructions above."
fi 