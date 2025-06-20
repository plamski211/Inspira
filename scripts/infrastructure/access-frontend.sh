#!/bin/bash

# Script to access the frontend directly
set -e

echo "=== Setting up direct access to the frontend ==="

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed or not in your PATH."
    exit 1
fi

# Check if the frontend service exists
kubectl get service frontend -n microservices &> /dev/null
if [ $? -ne 0 ]; then
    echo "Error: frontend service not found in the microservices namespace."
    exit 1
fi

# Set up port forwarding
echo "Setting up port forwarding from localhost:8080 to the frontend service..."
echo "This will allow you to access the frontend directly, bypassing the ingress controller."
echo "Press Ctrl+C to stop port forwarding when done."
echo ""
echo "Once port forwarding is active, you can access the frontend at:"
echo "http://localhost:8080"
echo ""
echo "Starting port forwarding..."
kubectl port-forward -n microservices svc/frontend 8080:80 