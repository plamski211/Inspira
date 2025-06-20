#!/bin/bash

# Get the Grafana admin password
GRAFANA_PASSWORD=$(kubectl get secret --namespace monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode)
echo "Grafana admin password: $GRAFANA_PASSWORD"

# Port forward to access Grafana
echo "Starting port forwarding to Grafana on port 3000..."
echo "Access Grafana at: http://localhost:3000"
echo "Username: admin"
echo "Password: $GRAFANA_PASSWORD"
echo "Press Ctrl+C to stop port forwarding"
kubectl port-forward --namespace monitoring svc/prometheus-grafana 3000:80
