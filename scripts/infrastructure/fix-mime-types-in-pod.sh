#!/bin/bash

# Script to directly fix MIME types in the running frontend pod
set -e

echo "=== Fixing MIME types in the running frontend pod ==="

# Find the frontend pod
FRONTEND_POD=$(kubectl get pods -n microservices -l app=frontend -o jsonpath='{.items[0].metadata.name}')

if [ -z "$FRONTEND_POD" ]; then
  echo "Error: No frontend pod found."
  exit 1
fi

echo "Found frontend pod: $FRONTEND_POD"

# Create a proper nginx.conf file with correct MIME types
echo "Creating optimized nginx.conf..."
cat > nginx-fixed.conf << EOF
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    # MIME types
    include /etc/nginx/mime.types;
    
    # Additional MIME type declarations
    types {
        application/javascript js;
        text/css css;
    }

    # Serve static files
    location / {
        try_files \$uri \$uri/ /index.html;
        add_header 'Access-Control-Allow-Origin' '*';
    }

    # JavaScript files - explicitly set content type
    location ~* \\.js$ {
        add_header Content-Type application/javascript;
        try_files \$uri =404;
    }

    # CSS files - explicitly set content type
    location ~* \\.css$ {
        add_header Content-Type text/css;
        try_files \$uri =404;
    }

    # Asset files
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
    }
}
EOF

# Copy the file to the pod
echo "Copying nginx.conf to the pod..."
kubectl cp nginx-fixed.conf microservices/$FRONTEND_POD:/tmp/nginx-fixed.conf

# Update the nginx configuration in the pod
echo "Updating nginx configuration in the pod..."
kubectl exec -n microservices $FRONTEND_POD -- sh -c "cp /tmp/nginx-fixed.conf /etc/nginx/conf.d/default.conf"

# Reload nginx
echo "Reloading nginx configuration..."
kubectl exec -n microservices $FRONTEND_POD -- sh -c "nginx -s reload"

# Clean up
rm nginx-fixed.conf

echo "=== MIME types fixed in the frontend pod ==="
echo "The frontend should now serve JavaScript and CSS files with correct MIME types."
echo "Access the application at http://4.156.37.48" 