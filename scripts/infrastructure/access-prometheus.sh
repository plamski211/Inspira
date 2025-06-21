#!/bin/bash

# Script to access Prometheus in the Kubernetes cluster
# with automatic port selection if the default port is already in use

# Default port
DEFAULT_PORT=9090
PORT=$DEFAULT_PORT

# Function to check if a port is available
is_port_available() {
    local port=$1
    if command -v nc &> /dev/null; then
        nc -z localhost $port &> /dev/null
        if [ $? -eq 0 ]; then
            return 1  # Port is in use
        else
            return 0  # Port is available
        fi
    elif command -v lsof &> /dev/null; then
        lsof -i:$port &> /dev/null
        if [ $? -eq 0 ]; then
            return 1  # Port is in use
        else
            return 0  # Port is available
        fi
    else
        # If we can't check, assume it's available
        return 0
    fi
}

# Find an available port
find_available_port() {
    local port=$DEFAULT_PORT
    local max_port=$((DEFAULT_PORT + 100))
    
    while [ $port -lt $max_port ]; do
        if is_port_available $port; then
            echo $port
            return 0
        fi
        port=$((port + 1))
    done
    
    echo "No available ports found in range $DEFAULT_PORT-$max_port"
    return 1
}

# Find an available port
PORT=$(find_available_port)

if [ $? -ne 0 ]; then
    echo "Failed to find an available port. Please free up some ports and try again."
    exit 1
fi

echo "Starting port forwarding to Prometheus on port $PORT..."
echo "Access Prometheus at: http://localhost:$PORT"
echo "Press Ctrl+C to stop port forwarding"

# Start port forwarding
kubectl port-forward -n monitoring service/prometheus-server $PORT:80
