#!/bin/bash

# Heavy load test script to trigger autoscaling
# This script uses multiple approaches to generate heavy CPU load

# Default values
DURATION=300  # 5 minutes
CONCURRENT=200 # Concurrent connections
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
      echo "  --concurrent=NUMBER   Number of concurrent connections (default: 200)"
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
RESULTS_DIR="heavy-load-results"
mkdir -p "$RESULTS_DIR"
LOG_FILE="$RESULTS_DIR/heavy-load-test-$(date +"%Y%m%d_%H%M%S").log"

echo "========================================="
echo "Starting Heavy Load Test for Autoscaling"
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

# Function to make rapid health check requests
make_health_requests() {
  local id=$1
  local endpoints=(
    "/api/gateway/health"
    "/api/users/health"
    "/api/content/health"
    "/api/media/health"
  )
  
  while true; do
    current_time=$(date +%s)
    if [ $current_time -ge $end_time ]; then
      break
    fi
    
    # Make requests to all endpoints in rapid succession
    for endpoint in "${endpoints[@]}"; do
      curl -s "http://$TARGET:$PORT$endpoint" > /dev/null &
    done
    
    # Very short sleep to allow for more requests per second
    sleep 0.01
  done
}

# Function to create user profiles rapidly
create_users() {
  local id=$1
  
  while true; do
    current_time=$(date +%s)
    if [ $current_time -ge $end_time ]; then
      break
    fi
    
    # Generate random user data
    uuid=$(date +"%s-%N-$RANDOM")
    user_data="{\"auth0Id\":\"load-test-$uuid\",\"displayName\":\"Load Test User $id-$uuid\",\"avatarUrl\":\"https://example.com/avatar.png\"}"
    
    # Send multiple requests in parallel
    for i in {1..10}; do
      curl -s -X POST -H "Content-Type: application/json" -d "$user_data" "http://$TARGET:$PORT/api/users/profiles/debug/direct-create" > /dev/null &
    done
    
    # Very short sleep
    sleep 0.05
  done
}

# Function to simulate content uploads
upload_content() {
  local id=$1
  
  while true; do
    current_time=$(date +%s)
    if [ $current_time -ge $end_time ]; then
      break
    fi
    
    # Create a temporary file with random content
    temp_file=$(mktemp)
    dd if=/dev/urandom of="$temp_file" bs=1024 count=1024 2>/dev/null
    
    # Upload the file
    curl -s -X POST -F "file=@$temp_file" -F "title=Load Test $id-$RANDOM" -F "description=Test description" "http://$TARGET:$PORT/api/content/upload" > /dev/null &
    
    # Clean up
    rm "$temp_file"
    
    # Short sleep
    sleep 0.1
  done
}

# Start multiple worker processes for health checks
echo "Starting health check workers..."
for i in $(seq 1 $((CONCURRENT / 4))); do
  make_health_requests "$i" &
  # Stagger the start of workers
  sleep 0.01
done

# Start multiple worker processes for user creation
echo "Starting user creation workers..."
for i in $(seq 1 $((CONCURRENT / 4 + 1)) $((CONCURRENT / 2))); do
  create_users "$i" &
  # Stagger the start of workers
  sleep 0.01
done

# Start multiple worker processes for content upload
echo "Starting content upload workers..."
for i in $(seq $((CONCURRENT / 2 + 1)) $((3 * CONCURRENT / 4))); do
  upload_content "$i" &
  # Stagger the start of workers
  sleep 0.01
done

# Start mixed workload workers
echo "Starting mixed workload workers..."
for i in $(seq $((3 * CONCURRENT / 4 + 1)) $CONCURRENT); do
  # Each worker randomly chooses what to do
  (
    while true; do
      current_time=$(date +%s)
      if [ $current_time -ge $end_time ]; then
        break
      fi
      
      # Randomly choose an action
      action=$((RANDOM % 3))
      case $action in
        0)
          # Health check
          endpoint=$((RANDOM % 4))
          case $endpoint in
            0) curl -s "http://$TARGET:$PORT/api/gateway/health" > /dev/null ;;
            1) curl -s "http://$TARGET:$PORT/api/users/health" > /dev/null ;;
            2) curl -s "http://$TARGET:$PORT/api/content/health" > /dev/null ;;
            3) curl -s "http://$TARGET:$PORT/api/media/health" > /dev/null ;;
          esac
          ;;
        1)
          # Create user
          uuid=$(date +"%s-%N-$RANDOM")
          user_data="{\"auth0Id\":\"load-test-$uuid\",\"displayName\":\"Load Test User $i-$uuid\",\"avatarUrl\":\"https://example.com/avatar.png\"}"
          curl -s -X POST -H "Content-Type: application/json" -d "$user_data" "http://$TARGET:$PORT/api/users/profiles/debug/direct-create" > /dev/null
          ;;
        2)
          # Generate CPU load
          for j in {1..5000}; do
            echo "$i-$j-$RANDOM" | md5sum > /dev/null
          done
          ;;
      esac
      
      # Very short sleep
      sleep 0.0$((RANDOM % 10))
    done
  ) &
  # Stagger the start of workers
  sleep 0.01
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