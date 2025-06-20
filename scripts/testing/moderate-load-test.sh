#!/bin/bash

# Moderate load test script to trigger autoscaling
# This script uses a more moderate approach to generate load

# Default values
DURATION=300  # 5 minutes
CONCURRENT=50 # Concurrent connections
TARGET="4.156.37.48"
PORT="80"

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
      echo "  --duration=SECONDS    Test duration in seconds (default: 300)"
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
RESULTS_DIR="load-results"
mkdir -p "$RESULTS_DIR"
LOG_FILE="$RESULTS_DIR/load-test-$(date +"%Y%m%d_%H%M%S").log"

echo "========================================="
echo "Starting Moderate Load Test for Autoscaling"
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

# Open another terminal to monitor pods
echo "Opening terminal to monitor Kubernetes pods..."
osascript -e 'tell application "Terminal" to do script "kubectl get pods -n microservices -w"' &

# Wait a moment
sleep 2

# Start time
start_time=$(date +%s)
end_time=$((start_time + DURATION))

# Create a pool of workers
worker_count=0
max_workers=$CONCURRENT

# Function to run a worker process
run_worker() {
  local id=$1
  local type=$2
  
  # Log worker start
  echo "[$(date +"%Y-%m-%d %H:%M:%S")] Starting worker $id of type $type" >> "$LOG_FILE"
  
  # Run until the end time
  while [ $(date +%s) -lt $end_time ]; do
    case $type in
      "health")
        # Choose a random health endpoint
        endpoint=$((RANDOM % 4))
        case $endpoint in
          0) url="/api/gateway/health" ;;
          1) url="/api/users/health" ;;
          2) url="/api/content/health" ;;
          3) url="/api/media/health" ;;
        esac
        
        # Make the request
        response=$(curl -s -w "%{http_code}" "http://$TARGET:$PORT$url")
        echo "[$(date +"%Y-%m-%d %H:%M:%S")] Worker $id: $url - Status: $response" >> "$LOG_FILE"
        ;;
        
      "user")
        # Generate random user data
        uuid=$(date +"%s-$RANDOM")
        user_data="{\"auth0Id\":\"load-test-$uuid\",\"displayName\":\"Load Test User $id\",\"avatarUrl\":\"https://example.com/avatar.png\"}"
        
        # Create a user
        response=$(curl -s -w "%{http_code}" -X POST -H "Content-Type: application/json" -d "$user_data" "http://$TARGET:$PORT/api/users/profiles/debug/direct-create")
        echo "[$(date +"%Y-%m-%d %H:%M:%S")] Worker $id: Created user - Status: $response" >> "$LOG_FILE"
        ;;
        
      "content")
        # Create a small file
        temp_file=$(mktemp)
        echo "This is a test file for load testing. Worker ID: $id, Time: $(date)" > "$temp_file"
        
        # Upload the file
        response=$(curl -s -w "%{http_code}" -X POST -F "file=@$temp_file" -F "title=Load Test $id" -F "description=Test description" "http://$TARGET:$PORT/api/content/upload")
        echo "[$(date +"%Y-%m-%d %H:%M:%S")] Worker $id: Uploaded content - Status: $response" >> "$LOG_FILE"
        
        # Clean up
        rm "$temp_file"
        ;;
    esac
    
    # Sleep for a random time between 0.5 and 2 seconds
    sleep $(awk -v min=0.5 -v max=2 'BEGIN{srand(); print min+rand()*(max-min)}')
  done
  
  echo "[$(date +"%Y-%m-%d %H:%M:%S")] Worker $id of type $type completed" >> "$LOG_FILE"
}

# Start health check workers
echo "Starting health check workers..."
for i in $(seq 1 $((CONCURRENT / 3))); do
  run_worker "$i" "health" &
  worker_count=$((worker_count + 1))
  
  # Stagger the start of workers
  sleep 0.5
done

# Start user creation workers
echo "Starting user creation workers..."
for i in $(seq $((CONCURRENT / 3 + 1)) $((2 * CONCURRENT / 3))); do
  run_worker "$i" "user" &
  worker_count=$((worker_count + 1))
  
  # Stagger the start of workers
  sleep 0.5
done

# Start content upload workers
echo "Starting content upload workers..."
for i in $(seq $((2 * CONCURRENT / 3 + 1)) $CONCURRENT); do
  run_worker "$i" "content" &
  worker_count=$((worker_count + 1))
  
  # Stagger the start of workers
  sleep 0.5
done

echo "Started $worker_count workers"
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

# Kill all background processes
pkill -P $$

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