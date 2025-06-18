#!/bin/bash

# Script to access the Grafana dashboard
# Usage: ./access-grafana.sh

echo "Setting up port forwarding to Grafana dashboard..."
echo "Once connected, you can access Grafana at: http://localhost:3000"
echo "Default credentials: admin / prom-operator"
echo "Press Ctrl+C to stop port forwarding"
echo ""

kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring 