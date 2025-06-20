#!/bin/bash

# Combined script to run load tests and verify autoscaling
# This script runs a load test and monitors autoscaling in parallel

set -e

# Default values
DURATION=300  # Test duration in seconds
THREADS=50    # Number of concurrent users
RAMP_UP=60    # Ramp-up period in seconds
TEST_HOST="localhost"
TEST_PORT="8000"
NAMESPACE="microservices"
CHECK_INTERVAL=10  # seconds

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --duration=*)
      DURATION="${1#*=}"
      shift
      ;;
    --threads=*)
      THREADS="${1#*=}"
      shift
      ;;
    --ramp-up=*)
      RAMP_UP="${1#*=}"
      shift
      ;;
    --host=*)
      TEST_HOST="${1#*=}"
      shift
      ;;
    --port=*)
      TEST_PORT="${1#*=}"
      shift
      ;;
    --namespace=*)
      NAMESPACE="${1#*=}"
      shift
      ;;
    --interval=*)
      CHECK_INTERVAL="${1#*=}"
      shift
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  --duration=SECONDS     Test duration in seconds (default: 300)"
      echo "  --threads=NUMBER       Number of concurrent users (default: 50)"
      echo "  --ramp-up=SECONDS      Ramp-up period in seconds (default: 60)"
      echo "  --host=HOSTNAME        Target host (default: localhost)"
      echo "  --port=PORT            Target port (default: 8000)"
      echo "  --namespace=NAMESPACE  Kubernetes namespace (default: microservices)"
      echo "  --interval=SECONDS     Check interval in seconds (default: 10)"
      echo "  --help                 Display this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Check if the required scripts exist
LOAD_TEST_SCRIPT="$(dirname "$0")/load-test.sh"
AUTOSCALING_SCRIPT="$(dirname "$0")/verify-autoscaling.sh"

if [ ! -f "$LOAD_TEST_SCRIPT" ]; then
  echo "Error: Load test script not found at $LOAD_TEST_SCRIPT"
  exit 1
fi

if [ ! -f "$AUTOSCALING_SCRIPT" ]; then
  echo "Error: Autoscaling verification script not found at $AUTOSCALING_SCRIPT"
  exit 1
fi

# Make sure the scripts are executable
chmod +x "$LOAD_TEST_SCRIPT"
chmod +x "$AUTOSCALING_SCRIPT"

echo "========================================="
echo "Starting Combined Load Test and Autoscaling Verification"
echo "========================================="
echo "Load Test Parameters:"
echo "- Duration: $DURATION seconds"
echo "- Concurrent Users: $THREADS"
echo "- Ramp-up Period: $RAMP_UP seconds"
echo "- Target: http://$TEST_HOST:$TEST_PORT"
echo
echo "Autoscaling Verification Parameters:"
echo "- Namespace: $NAMESPACE"
echo "- Check Interval: $CHECK_INTERVAL seconds"
echo "========================================="

# Create a timestamp for this test run
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RESULTS_DIR="load-test-results-${TIMESTAMP}"
mkdir -p "$RESULTS_DIR"

# Start the autoscaling verification in the background
echo "Starting autoscaling verification..."
"$AUTOSCALING_SCRIPT" --namespace="$NAMESPACE" --interval="$CHECK_INTERVAL" --duration="$DURATION" > "$RESULTS_DIR/autoscaling-output.log" 2>&1 &
AUTOSCALING_PID=$!

# Wait a moment to ensure autoscaling verification has started
sleep 2

# Start the load test
echo "Starting load test..."
"$LOAD_TEST_SCRIPT" --duration="$DURATION" --threads="$THREADS" --ramp-up="$RAMP_UP" --host="$TEST_HOST" --port="$TEST_PORT" > "$RESULTS_DIR/load-test-output.log" 2>&1
LOAD_TEST_EXIT_CODE=$?

# Wait for the autoscaling verification to complete
echo "Waiting for autoscaling verification to complete..."
wait "$AUTOSCALING_PID"
AUTOSCALING_EXIT_CODE=$?

# Copy the results files to our results directory
cp autoscaling_log_*.txt "$RESULTS_DIR/" 2>/dev/null || true
cp autoscaling_results_*.json "$RESULTS_DIR/" 2>/dev/null || true
cp load-test-results/* "$RESULTS_DIR/" 2>/dev/null || true

# Generate a simple HTML report
cat > "$RESULTS_DIR/report.html" << EOF
<!DOCTYPE html>
<html>
<head>
  <title>Load Test and Autoscaling Report</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; }
    h1, h2 { color: #333; }
    .section { margin-bottom: 30px; }
    .success { color: green; }
    .warning { color: orange; }
    .error { color: red; }
    pre { background-color: #f5f5f5; padding: 10px; border-radius: 5px; overflow-x: auto; }
    table { border-collapse: collapse; width: 100%; }
    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
    th { background-color: #f2f2f2; }
    tr:nth-child(even) { background-color: #f9f9f9; }
  </style>
</head>
<body>
  <h1>Load Test and Autoscaling Report</h1>
  <p>Test run at: $(date)</p>
  
  <div class="section">
    <h2>Test Parameters</h2>
    <table>
      <tr><th>Parameter</th><th>Value</th></tr>
      <tr><td>Duration</td><td>${DURATION} seconds</td></tr>
      <tr><td>Concurrent Users</td><td>${THREADS}</td></tr>
      <tr><td>Ramp-up Period</td><td>${RAMP_UP} seconds</td></tr>
      <tr><td>Target</td><td>http://${TEST_HOST}:${TEST_PORT}</td></tr>
      <tr><td>Kubernetes Namespace</td><td>${NAMESPACE}</td></tr>
    </table>
  </div>
  
  <div class="section">
    <h2>Load Test Summary</h2>
    <pre>$(cat "$RESULTS_DIR/load-test-output.log" | tail -20)</pre>
  </div>
  
  <div class="section">
    <h2>Autoscaling Summary</h2>
    <pre>$(cat "$RESULTS_DIR/autoscaling-output.log" | grep -A 20 "Summary:")</pre>
  </div>
  
  <div class="section">
    <h2>Conclusion</h2>
    <p>
      Load Test Status: 
      $(if [ $LOAD_TEST_EXIT_CODE -eq 0 ]; then 
          echo "<span class='success'>Success</span>"; 
        else 
          echo "<span class='error'>Failed (Exit code: $LOAD_TEST_EXIT_CODE)</span>"; 
        fi)
    </p>
    <p>
      Autoscaling Verification Status: 
      $(if [ $AUTOSCALING_EXIT_CODE -eq 0 ]; then 
          echo "<span class='success'>Success</span>"; 
        else 
          echo "<span class='error'>Failed (Exit code: $AUTOSCALING_EXIT_CODE)</span>"; 
        fi)
    </p>
    <p>
      $(if grep -q "Autoscaling worked" "$RESULTS_DIR/autoscaling-output.log"; then
          echo "<span class='success'>✅ Autoscaling worked successfully! The system scaled up under load.</span>";
        elif grep -q "No scaling occurred" "$RESULTS_DIR/autoscaling-output.log"; then
          echo "<span class='warning'>⚠️ No scaling occurred. Consider increasing the load or checking HPA configuration.</span>";
        else
          echo "<span class='error'>❌ Could not determine if autoscaling worked correctly.</span>";
        fi)
    </p>
  </div>
</body>
</html>
EOF

echo "========================================="
echo "Test Completed!"
echo "Results saved to: $RESULTS_DIR/"
echo "Report: $RESULTS_DIR/report.html"
echo "========================================="

# Clean up temporary files
rm -f autoscaling_log_*.txt autoscaling_results_*.json 2>/dev/null || true

# Exit with the load test exit code
exit $LOAD_TEST_EXIT_CODE 