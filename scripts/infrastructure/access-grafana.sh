#!/bin/bash

# Script to access Grafana

DEFAULT_PORT=3000
PORT=$DEFAULT_PORT
MAX_PORT=3010

# Get Grafana admin password
GRAFANA_PASSWORD=$(kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" 2>/dev/null | base64 --decode || echo "admin")
echo "Grafana admin password: $GRAFANA_PASSWORD"

echo "Starting port forwarding to Grafana on port $PORT..."

# Try ports in range until one works
while [ $PORT -le $MAX_PORT ]; do
  kubectl port-forward -n monitoring service/grafana $PORT:$DEFAULT_PORT 2>/tmp/port_error &
  PF_PID=$!
  sleep 2
  
  if grep -q "address already in use" /tmp/port_error; then
    echo "Port $PORT is already in use, trying next port..."
    kill $PF_PID 2>/dev/null
    PORT=$((PORT + 1))
  else
    echo "Access Grafana at: http://localhost:$PORT"
    echo "Username: admin"
    echo "Password: $GRAFANA_PASSWORD"
    echo "Press Ctrl+C to stop port forwarding"
    wait $PF_PID
    break
  fi
done

if [ $PORT -gt $MAX_PORT ]; then
  echo "Error: Could not find an available port in range $DEFAULT_PORT-$MAX_PORT"
  exit 1
fi
