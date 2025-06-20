#!/bin/bash

# Script to trigger autoscaling by generating CPU load on a specific service
# This is useful for demonstrating and testing the HPA functionality

set -e

# Default values
SERVICE="content-service"
NAMESPACE="microservices"
DURATION=300  # 5 minutes
CPU_LOAD=80   # percentage

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -s|--service)
      SERVICE="$2"
      shift
      shift
      ;;
    -n|--namespace)
      NAMESPACE="$2"
      shift
      shift
      ;;
    -d|--duration)
      DURATION="$2"
      shift
      shift
      ;;
    -c|--cpu-load)
      CPU_LOAD="$2"
      shift
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  -s, --service SERVICE    Service to target (default: content-service)"
      echo "  -n, --namespace NS       Namespace (default: microservices)"
      echo "  -d, --duration SECONDS   Duration in seconds (default: 300)"
      echo "  -c, --cpu-load PERCENT   CPU load percentage (default: 80)"
      echo "  -h, --help               Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo "Starting autoscale test for $SERVICE in namespace $NAMESPACE"
echo "Duration: $DURATION seconds"
echo "Target CPU load: $CPU_LOAD%"

# Get the pod name for the specified service
POD_NAME=$(kubectl get pods -n $NAMESPACE -l app=$SERVICE -o jsonpath="{.items[0].metadata.name}")

if [ -z "$POD_NAME" ]; then
  echo "Error: No pods found for service $SERVICE in namespace $NAMESPACE"
  exit 1
fi

echo "Target pod: $POD_NAME"

# Get current HPA status
echo "Current HPA status:"
kubectl get hpa -n $NAMESPACE | grep $SERVICE

# Start monitoring in background
(
  end_time=$(($(date +%s) + $DURATION))
  while [ $(date +%s) -lt $end_time ]; do
    echo "Time remaining: $((end_time - $(date +%s))) seconds"
    echo "Checking CPU usage at $(date):"
    kubectl top pods -n $NAMESPACE | grep $SERVICE
    kubectl get hpa -n $NAMESPACE | grep $SERVICE
    sleep 10
  done
) &
MONITOR_PID=$!

# Generate CPU load in the pod
echo "Generating CPU load in $POD_NAME..."
kubectl exec -n $NAMESPACE $POD_NAME -- bash -c "apt-get update && apt-get install -y stress-ng && stress-ng --cpu 1 --cpu-load $CPU_LOAD --timeout ${DURATION}s" &
STRESS_PID=$!

# Wait for the stress test to complete
wait $STRESS_PID

# Give HPA some time to react
echo "CPU load generation completed. Waiting for HPA to react..."
sleep 30

# Show final state
echo "==========================================="
echo "Final HPA status:"
kubectl get hpa -n $NAMESPACE | grep $SERVICE

echo "Final pod status:"
kubectl get pods -n $NAMESPACE | grep $SERVICE
echo "==========================================="

# Kill the monitoring process
kill $MONITOR_PID 2>/dev/null || true

echo "Autoscale test completed."
