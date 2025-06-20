#!/bin/bash

# Script to force MIME types in the Nginx ingress controller
set -e

echo "=== Fixing MIME type issues in Nginx ingress controller ==="

# Find the Nginx ingress controller pods that are actually running
NGINX_PODS=$(kubectl get pods -n ingress-basic -l app.kubernetes.io/component=controller --field-selector=status.phase=Running -o jsonpath='{.items[*].metadata.name}')

if [ -z "$NGINX_PODS" ]; then
  echo "No running ingress controller pods found. Trying another selector..."
  NGINX_PODS=$(kubectl get pods -n ingress-basic --field-selector=status.phase=Running -o jsonpath='{.items[*].metadata.name}')
fi

if [ -z "$NGINX_PODS" ]; then
  echo "Error: No running pods found in the ingress-basic namespace."
  exit 1
fi

echo "Found running pods: $NGINX_PODS"

for POD in $NGINX_PODS; do
  echo "Modifying MIME types in pod: $POD"
  
  # Create a more complete MIME types file
  kubectl exec -n ingress-basic $POD -- sh -c "cat > /tmp/mime.types << 'EOF'
types {
    text/html                                        html htm shtml;
    text/css                                         css;
    application/javascript                           js;
    text/xml                                         xml;
    image/gif                                        gif;
    image/jpeg                                       jpeg jpg;
    application/json                                 json;
    image/png                                        png;
    image/svg+xml                                    svg svgz;
    image/webp                                       webp;
    image/x-icon                                     ico;
    font/woff                                        woff;
    font/woff2                                       woff2;
    application/zip                                  zip;
    text/plain                                       txt;
}
EOF"

  # Copy the file to the correct location
  kubectl exec -n ingress-basic $POD -- sh -c "cp /tmp/mime.types /etc/nginx/mime.types"
  
  # Reload Nginx configuration
  kubectl exec -n ingress-basic $POD -- sh -c "nginx -s reload"

  echo "MIME types updated in pod: $POD"
done

echo "=== MIME type configuration updated in all ingress controller pods ==="
echo "Wait a few seconds for the configuration to take effect..."
sleep 5

# Verify MIME types by checking an endpoint
echo "Testing JavaScript MIME type..."
curl -I http://4.156.37.48/assets/index-e753e2ec.js

echo "Testing CSS MIME type..."
curl -I http://4.156.37.48/assets/index-362916f1.css

echo "=== Testing complete ==="
echo "If you still have MIME type issues, try accessing the application directly:"
echo "http://4.156.37.48" 