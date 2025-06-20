#!/bin/bash

# Simple script to trigger autoscaling by generating load

# Default values
DURATION=600  # 10 minutes
CONCURRENT=50 # Concurrent connections
TARGET="4.156.37.48"
PORT="80"
ENDPOINTS=(
  "/api/gateway/health"
  "/api/users/health"
  "/api/content/health"
  "/api/media/health"
)

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --duration=*)
      DURATION="${1#*=}"
      shift
      ;;
    --concurrent=*)
      CONCURRENT="${1#*=}"
      shift
      ;;
    --target=*)
      TARGET="${1#*=}"
      shift
      ;;
    --port=*)
      PORT="${1#*=}"
      shift
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  --duration=SECONDS    Test duration in seconds (default: 600)"
      echo "  --concurrent=NUMBER   Number of concurrent connections (default: 50)"
      echo "  --target=HOSTNAME     Target host (default: 4.156.37.48)"
      echo "  --port=PORT           Target port (default: 80)"
      echo "  --help                Display this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Create results directory
RESULTS_DIR="autoscale-results"
mkdir -p "$RESULTS_DIR"
LOG_FILE="$RESULTS_DIR/autoscale-test-$(date +"%Y%m%d_%H%M%S").log"

echo "========================================="
echo "Starting Autoscaling Test"
echo "========================================="
echo "Test Parameters:"
echo "- Duration: $DURATION seconds"
echo "- Concurrent Connections: $CONCURRENT"
echo "- Target: http://$TARGET:$PORT"
echo "- Log File: $LOG_FILE"
echo "========================================="

# Open a terminal to monitor Kubernetes autoscaling
echo "Opening terminal to monitor Kubernetes autoscaling..."
osascript -e 'tell application "Terminal" to do script "kubectl get hpa -n microservices -w"' &

# Wait a moment
sleep 2

# Start time
start_time=$(date +%s)
end_time=$((start_time + DURATION))

# Function to make requests
make_requests() {
  local endpoint=$1
  local id=$2
  
  while true; do
    current_time=$(date +%s)
    if [ $current_time -ge $end_time ]; then
      break
    fi
    
    # Make request and log result
    response=$(curl -s -w "%{http_code}" "http://$TARGET:$PORT$endpoint")
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] Worker $id: $endpoint - Status: $response" >> "$LOG_FILE"
    
    # Add some randomness to avoid synchronized requests
    sleep 0.$((RANDOM % 5))
  done
}

# Start background workers for basic health checks
echo "Starting health check workers..."
for i in $(seq 1 $((CONCURRENT / 2))); do
  endpoint=${ENDPOINTS[$((RANDOM % ${#ENDPOINTS[@]}))]}
  make_requests "$endpoint" "$i" &
  # Stagger the start of workers
  sleep 0.$((RANDOM % 10))
done

# Start CPU-intensive workers
echo "Starting CPU-intensive workers..."
for i in $(seq $((CONCURRENT / 2 + 1)) $CONCURRENT); do
  # Create random user profiles - more CPU intensive
  (
    while true; do
      current_time=$(date +%s)
      if [ $current_time -ge $end_time ]; then
        break
      fi
      
      # Generate random user data
      uuid=$(uuidgen || cat /proc/sys/kernel/random/uuid || date +"%s-%N")
      user_data="{\"auth0Id\":\"load-test-$uuid\",\"displayName\":\"Load Test User $i\",\"avatarUrl\":\"https://example.com/avatar.png\"}"
      
      # Post to user creation endpoint
      response=$(curl -s -w "%{http_code}" -X POST -H "Content-Type: application/json" -d "$user_data" "http://$TARGET:$PORT/api/users/profiles/debug/direct-create")
      echo "[$(date +"%Y-%m-%d %H:%M:%S")] Worker $i: CPU-intensive - Status: $response" >> "$LOG_FILE"
      
      # Generate some CPU load locally
      for j in {1..1000}; do
        echo "$uuid-$j" | md5sum > /dev/null
      done
      
      # Random sleep between 0.1 and 1 second
      sleep 0.$((RANDOM % 10 + 1))
    done
  ) &
  # Stagger the start of workers
  sleep 0.$((RANDOM % 5 + 1))
done

echo "Test is running... Press Ctrl+C to stop early."
echo "Monitoring Kubernetes autoscaling in the other terminal."

# Wait for the test duration
remaining=$DURATION
while [ $remaining -gt 0 ]; do
  echo -ne "Time remaining: $remaining seconds\r"
  sleep 1
  remaining=$((remaining - 1))
done

echo -e "\nTest completed! Waiting for background processes to finish..."

# Wait for all background processes to finish
wait

echo "========================================="
echo "Test Completed!"
echo "Results saved to: $LOG_FILE"
echo "========================================="

# Check if autoscaling occurred
echo "Checking if autoscaling occurred..."
kubectl get hpa -n microservices

echo "========================================="
echo "To view pods, run: kubectl get pods -n microservices"
echo "To view detailed HPA status, run: kubectl describe hpa -n microservices"
echo "=========================================" 