#!/bin/bash

# Port forward to access Prometheus
echo "Starting port forwarding to Prometheus on port 9090..."
echo "Access Prometheus at: http://localhost:9090"
echo "Press Ctrl+C to stop port forwarding"
kubectl port-forward --namespace monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
