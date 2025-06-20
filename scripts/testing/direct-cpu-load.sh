#!/bin/bash

# Script to generate CPU load directly in a pod using a simple approach

# Default values
NAMESPACE="microservices"
SERVICE="content-service"
DURATION=300  # 5 minutes

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --namespace=*)
      NAMESPACE="${1#*=}"
      shift
      ;;
    --service=*)
      SERVICE="${1#*=}"
      shift
      ;;
    --duration=*)
      DURATION="${1#*=}"
      shift
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  --namespace=NAMESPACE   Kubernetes namespace (default: microservices)"
      echo "  --service=SERVICE       Service to test (default: content-service)"
      echo "  --duration=SECONDS      Test duration in seconds (default: 300)"
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
echo "Starting Direct CPU Load Generator for Kubernetes Pods"
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

# Create a simple shell script to generate CPU load
CPU_LOAD_SCRIPT=$(cat <<'EOF'
#!/bin/sh
# Simple CPU load generator
echo "Starting CPU load generator..."
for i in $(seq 1 4); do
  while true; do
    # Generate CPU load with a simple calculation
    x=0
    while [ $x -lt 10000 ]; do
      x=$((x+1))
    done
  done &
done

# Keep script running for the specified duration
echo "CPU load generator running. Will stop after $1 seconds."
sleep $1

# Kill all background processes
echo "Stopping CPU load generator..."
pkill -P $$
EOF
)

# Copy the script to the pod
echo "Copying CPU load script to pod..."
kubectl cp - $NAMESPACE/$POD_NAME:/tmp/cpu-load.sh <<< "$CPU_LOAD_SCRIPT"

# Make the script executable
echo "Making script executable..."
kubectl exec -n $NAMESPACE $POD_NAME -- chmod +x /tmp/cpu-load.sh

# Run the script in the pod
echo "Running CPU load script in pod..."
kubectl exec -n $NAMESPACE $POD_NAME -- sh /tmp/cpu-load.sh $DURATION &
EXEC_PID=$!

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
    kubectl top pods -n $NAMESPACE -l app=$SERVICE
    kubectl get hpa -n $NAMESPACE | grep $SERVICE
  fi
done

echo -e "\nTest completed! Cleaning up..."

# Kill the exec process if still running
if [ ! -z "$EXEC_PID" ]; then
  kill $EXEC_PID 2>/dev/null || true
fi

# Try to kill the script in the pod
echo "Stopping CPU load in the pod..."
kubectl exec -n $NAMESPACE $POD_NAME -- pkill -f cpu-load.sh 2>/dev/null || true

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