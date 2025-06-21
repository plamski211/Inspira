#!/bin/bash

# Script to access Prometheus

DEFAULT_PORT=9090
PORT=$DEFAULT_PORT
MAX_PORT=9099

echo "Starting port forwarding to Prometheus on port $PORT..."

# Try ports in range until one works
while [ $PORT -le $MAX_PORT ]; do
  kubectl port-forward -n monitoring service/prometheus-server $PORT:$DEFAULT_PORT 2>/tmp/port_error &
  PF_PID=$!
  sleep 2
  
  if grep -q "address already in use" /tmp/port_error; then
    echo "Port $PORT is already in use, trying next port..."
    kill $PF_PID 2>/dev/null
    PORT=$((PORT + 1))
  else
    echo "Access Prometheus at: http://localhost:$PORT"
    echo "Username: admin"
    echo "Password: prom-operator"
    echo "Press Ctrl+C to stop port forwarding"
    wait $PF_PID
    break
  fi
done

if [ $PORT -gt $MAX_PORT ]; then
  echo "Error: Could not find an available port in range $DEFAULT_PORT-$MAX_PORT"
  exit 1
fi
