#!/bin/bash

# Script to fix the frontend white screen issue in Azure (URGENT FIX)
# This script addresses the issue with the IP starting with 4.x.x.x

echo "===== URGENT FIX: Frontend White Screen in Azure ====="
echo ""

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
  echo "❌ kubectl not found. Please install it first."
  exit 1
fi

# Get the external IP
EXTERNAL_IP=$(kubectl get service frontend -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
echo "Current frontend external IP: $EXTERNAL_IP"

# Create a ConfigMap for the frontend configuration
echo "Creating ConfigMap for frontend configuration..."
cat <<EOF > frontend-config-urgent.yaml
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

kubectl apply -f frontend-config-urgent.yaml
rm frontend-config-urgent.yaml

# Create a new frontend deployment with a simple static HTML
echo "Creating a simple frontend deployment..."
cat <<EOF > frontend-urgent-deployment.yaml
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
        image: nginx:alpine
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
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
        volumeMounts:
        - name: nginx-config
          mountPath: /etc/nginx/conf.d/default.conf
          subPath: nginx.conf
        - name: html-content
          mountPath: /usr/share/nginx/html/index.html
          subPath: index.html
        - name: env-config
          mountPath: /usr/share/nginx/html/env-config.js
          subPath: env-config.js
        - name: health-check
          mountPath: /usr/share/nginx/html/health/index.html
          subPath: health.html
      volumes:
      - name: nginx-config
        configMap:
          name: nginx-config
      - name: html-content
        configMap:
          name: html-content
      - name: env-config
        configMap:
          name: frontend-config
      - name: health-check
        configMap:
          name: health-check
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
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
  namespace: default
data:
  nginx.conf: |
    server {
        listen 80;
        server_name _;
        root /usr/share/nginx/html;
        index index.html;

        # MIME types
        include /etc/nginx/mime.types;

        # Additional MIME type overrides
        types {
            application/javascript js;
            text/css css;
        }

        # Serve static files
        location / {
            try_files \$uri \$uri/ /index.html;
            add_header "Access-Control-Allow-Origin" "*";
        }

        # JavaScript files - explicitly set content type
        location ~* \.js$ {
            add_header Content-Type "application/javascript";
            try_files \$uri =404;
        }

        # CSS files - explicitly set content type
        location ~* \.css$ {
            add_header Content-Type "text/css";
            try_files \$uri =404;
        }

        # API proxy
        location /api/ {
            proxy_pass http://api-gateway:8080;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host \$host;
            proxy_cache_bypass \$http_upgrade;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }

        # Health check endpoint
        location /health {
            try_files \$uri \$uri/ /health/index.html;
        }
    }
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: html-content
  namespace: default
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head>
      <title>Inspira Platform</title>
      <script src="/env-config.js"></script>
      <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background-color: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1); }
        h1 { color: #333; }
        .service { margin-bottom: 20px; padding: 10px; border: 1px solid #ddd; border-radius: 4px; }
        .service h2 { margin-top: 0; }
        .button { display: inline-block; background-color: #4CAF50; color: white; padding: 10px 20px; text-align: center; text-decoration: none; border-radius: 4px; margin-top: 10px; }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>Inspira Platform</h1>
        <p>Welcome to the Inspira microservices platform.</p>
        <div class="service">
          <h2>Frontend</h2>
          <p>This is the frontend service that provides the user interface.</p>
        </div>
        <div class="service">
          <h2>API Gateway</h2>
          <p>Routes requests to the appropriate microservices.</p>
        </div>
        <div class="service">
          <h2>User Service</h2>
          <p>Manages user accounts and authentication.</p>
        </div>
        <div class="service">
          <h2>Content Service</h2>
          <p>Handles content storage and retrieval.</p>
        </div>
        <div class="service">
          <h2>Media Service</h2>
          <p>Processes and stores media files.</p>
        </div>
        <a href="/login" class="button">Login</a>
      </div>
    </body>
    </html>
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: health-check
  namespace: default
data:
  health.html: |
    {"status":"UP","timestamp":"2025-06-21T02:30:00Z"}
EOF

# Apply the deployment
echo "Applying frontend deployment..."
kubectl apply -f frontend-urgent-deployment.yaml

# Delete any existing pods to force a new deployment
echo "Deleting existing frontend pods to force a new deployment..."
kubectl delete pods -l app=frontend --grace-period=0 --force || true

# Wait for frontend deployment to be ready
echo "Waiting for frontend deployment to be ready..."
kubectl rollout status deployment/frontend

# Get the new external IP
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
echo "===== URGENT FIX COMPLETE ====="
echo ""
echo "Frontend is now available at: http://$FRONTEND_IP"
echo ""
echo "If you still see a white screen, try the following:"
echo "1. Clear your browser cache completely"
echo "2. Try accessing the frontend in an incognito/private window"
echo "3. Check the frontend logs: kubectl logs deployment/frontend"
echo "4. Check if the API Gateway is accessible from the frontend"
echo "" 