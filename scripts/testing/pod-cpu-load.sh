#!/bin/bash

# Script to generate CPU load directly on Kubernetes pods
# This is useful for testing autoscaling when external load testing doesn't work

# Default values
NAMESPACE="microservices"
DURATION=300  # 5 minutes
SERVICE="content-service"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --namespace=*)
      NAMESPACE="${1#*=}"
      shift
      ;;
    --duration=*)
      DURATION="${1#*=}"
      shift
      ;;
    --service=*)
      SERVICE="${1#*=}"
      shift
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  --namespace=NAMESPACE   Kubernetes namespace (default: microservices)"
      echo "  --duration=SECONDS      Test duration in seconds (default: 300)"
      echo "  --service=SERVICE       Service to test (default: content-service)"
      echo "                          Options: content-service, user-service, api-gateway, media-service"
      echo "  --help                  Display this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo "========================================="
echo "Starting CPU Load Generator for Kubernetes Pods"
echo "========================================="
echo "Test Parameters:"
echo "- Namespace: $NAMESPACE"
echo "- Service: $SERVICE"
echo "- Duration: $DURATION seconds"
echo "========================================="

# Get pod name
POD_NAME=$(kubectl get pods -n $NAMESPACE -l app=$SERVICE -o jsonpath='{.items[0].metadata.name}')
if [ -z "$POD_NAME" ]; then
  echo "Error: No pod found for service $SERVICE in namespace $NAMESPACE"
  exit 1
fi

echo "Found pod: $POD_NAME"

# Open a terminal to monitor Kubernetes autoscaling
echo "Opening terminal to monitor Kubernetes autoscaling..."
osascript -e 'tell application "Terminal" to do script "kubectl get hpa -n microservices -w"' &

# Open another terminal to monitor pods
echo "Opening terminal to monitor Kubernetes pods..."
osascript -e 'tell application "Terminal" to do script "kubectl get pods -n microservices -w"' &

# Open another terminal to monitor CPU usage
echo "Opening terminal to monitor CPU usage..."
osascript -e 'tell application "Terminal" to do script "kubectl top pods -n microservices -l app='$SERVICE' --containers -w"' &

# Wait a moment
sleep 2

# Check if the pod is running a container that supports the stress command
echo "Checking if the pod supports stress command..."
if kubectl exec -it $POD_NAME -n $NAMESPACE -- which stress &>/dev/null; then
  echo "stress command is available in the pod."
  STRESS_AVAILABLE=true
else
  echo "stress command is not available in the pod."
  STRESS_AVAILABLE=false
fi

# Check if the pod is running a container that supports the dd command
echo "Checking if the pod supports dd command..."
if kubectl exec -it $POD_NAME -n $NAMESPACE -- which dd &>/dev/null; then
  echo "dd command is available in the pod."
  DD_AVAILABLE=true
else
  echo "dd command is not available in the pod."
  DD_AVAILABLE=false
fi

# Generate CPU load
echo "Generating CPU load on pod $POD_NAME..."

if [ "$STRESS_AVAILABLE" = true ]; then
  # Use stress if available
  echo "Using stress command to generate CPU load..."
  kubectl exec -it $POD_NAME -n $NAMESPACE -- sh -c "stress --cpu 4 --timeout ${DURATION}s" &
  STRESS_PID=$!
elif [ "$DD_AVAILABLE" = true ]; then
  # Use dd if available
  echo "Using dd command to generate CPU load..."
  kubectl exec -it $POD_NAME -n $NAMESPACE -- sh -c "dd if=/dev/zero of=/dev/null bs=1M count=10000 & dd if=/dev/zero of=/dev/null bs=1M count=10000 & dd if=/dev/zero of=/dev/null bs=1M count=10000 & dd if=/dev/zero of=/dev/null bs=1M count=10000 & sleep ${DURATION} && pkill dd" &
  DD_PID=$!
else
  # Use a simple shell loop as fallback
  echo "Using shell loop to generate CPU load..."
  kubectl exec -it $POD_NAME -n $NAMESPACE -- sh -c "for i in \$(seq 1 4); do while true; do echo \"scale=10000; 4*a(1)\" | bc -l > /dev/null & done; done & sleep ${DURATION} && pkill bc" &
  LOOP_PID=$!
fi

echo "CPU load generation started. Monitoring for $DURATION seconds..."

# Wait for the test duration
remaining=$DURATION
while [ $remaining -gt 0 ]; do
  echo -ne "Time remaining: $remaining seconds\r"
  sleep 1
  remaining=$((remaining - 1))
  
  # Check CPU usage every 10 seconds
  if [ $((remaining % 10)) -eq 0 ]; then
    echo -e "\nChecking CPU usage at $(date):"
    kubectl top pods -n $NAMESPACE -l app=$SERVICE --containers
  fi
done

echo -e "\nTest completed! Cleaning up..."

# Kill the load generation process if still running
if [ ! -z "$STRESS_PID" ]; then
  kill $STRESS_PID 2>/dev/null || true
fi
if [ ! -z "$DD_PID" ]; then
  kill $DD_PID 2>/dev/null || true
fi
if [ ! -z "$LOOP_PID" ]; then
  kill $LOOP_PID 2>/dev/null || true
fi

# Try to kill processes in the pod
echo "Stopping CPU load in the pod..."
kubectl exec -it $POD_NAME -n $NAMESPACE -- pkill stress 2>/dev/null || true
kubectl exec -it $POD_NAME -n $NAMESPACE -- pkill dd 2>/dev/null || true
kubectl exec -it $POD_NAME -n $NAMESPACE -- pkill bc 2>/dev/null || true

echo "========================================="
echo "Test Completed!"
echo "========================================="

# Check if autoscaling occurred
echo "Checking if autoscaling occurred..."
kubectl get hpa -n $NAMESPACE

echo "========================================="
echo "Final pod status:"
kubectl get pods -n $NAMESPACE -l app=$SERVICE
echo "=========================================" 