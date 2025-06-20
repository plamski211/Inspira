#!/bin/bash

# Simple script to generate CPU load in a Kubernetes pod

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
echo "Starting Simple CPU Load Generator"
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
osascript -e 'tell application "Terminal" to do script "kubectl get hpa -n '$NAMESPACE' -w"' &

# Open another terminal to monitor pods
echo "Opening terminal to monitor Kubernetes pods..."
osascript -e 'tell application "Terminal" to do script "kubectl get pods -n '$NAMESPACE' -w"' &

# Open another terminal to monitor CPU usage
echo "Opening terminal to monitor CPU usage..."
osascript -e 'tell application "Terminal" to do script "watch -n 5 \"kubectl top pods -n '$NAMESPACE' -l app='$SERVICE'\""' &

# Wait a moment
sleep 2

# Create a temporary file with the CPU load script
TEMP_SCRIPT=$(mktemp)
cat > $TEMP_SCRIPT << 'EOF'
#!/bin/sh
echo "Starting CPU load generator..."
# Run 4 CPU-intensive processes
yes > /dev/null &
yes > /dev/null &
yes > /dev/null &
yes > /dev/null &
echo "CPU load generator running..."
EOF

echo "Created temporary script: $TEMP_SCRIPT"

# Copy the script to the pod
echo "Copying CPU load script to pod..."
kubectl cp $TEMP_SCRIPT $NAMESPACE/$POD_NAME:/tmp/cpu-load.sh

# Make the script executable
echo "Making script executable..."
kubectl exec -n $NAMESPACE $POD_NAME -- chmod +x /tmp/cpu-load.sh

# Run the script in the pod
echo "Running CPU load script in pod..."
kubectl exec -n $NAMESPACE $POD_NAME -- /tmp/cpu-load.sh &

echo "CPU load generation started. Monitoring for $DURATION seconds..."

# Wait for the test duration
remaining=$DURATION
while [ $remaining -gt 0 ]; do
  echo -ne "Time remaining: $remaining seconds\r"
  sleep 10
  remaining=$((remaining - 10))
  
  # Check CPU usage
  echo -e "\nChecking CPU usage at $(date):"
  kubectl top pods -n $NAMESPACE -l app=$SERVICE
  kubectl get hpa -n $NAMESPACE | grep $SERVICE
done

echo -e "\nTest completed! Cleaning up..."

# Stop the CPU load in the pod
echo "Stopping CPU load in the pod..."
kubectl exec -n $NAMESPACE $POD_NAME -- pkill yes 2>/dev/null || true

# Clean up the temporary file
rm -f $TEMP_SCRIPT

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