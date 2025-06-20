#!/bin/bash

# Script to verify that autoscaling is working correctly
# This script monitors the number of pods during a load test

set -e

# Default values
NAMESPACE="microservices"
CHECK_INTERVAL=10  # seconds
DURATION=300       # seconds
SERVICES=("api-gateway" "user-service" "content-service" "media-service")

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --namespace=*)
      NAMESPACE="${1#*=}"
      shift
      ;;
    --interval=*)
      CHECK_INTERVAL="${1#*=}"
      shift
      ;;
    --duration=*)
      DURATION="${1#*=}"
      shift
      ;;
    --services=*)
      IFS=',' read -ra SERVICES <<< "${1#*=}"
      shift
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  --namespace=NAMESPACE   Kubernetes namespace (default: microservices)"
      echo "  --interval=SECONDS      Check interval in seconds (default: 10)"
      echo "  --duration=SECONDS      Total monitoring duration in seconds (default: 300)"
      echo "  --services=SVC1,SVC2    Comma-separated list of services to monitor"
      echo "                          (default: api-gateway,user-service,content-service,media-service)"
      echo "  --help                  Display this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
  echo "kubectl is not installed. Please install it first."
  exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
  echo "jq is not installed. Please install it first."
  exit 1
fi

# Create a temporary directory for logs
TEMP_DIR=$(mktemp -d)
LOG_FILE="$TEMP_DIR/autoscaling_log.txt"
RESULTS_FILE="$TEMP_DIR/autoscaling_results.json"

echo "{}" > "$RESULTS_FILE"

# Function to get the current number of pods for a service
get_pod_count() {
  local service=$1
  kubectl get pods -n "$NAMESPACE" -l app="$service" --no-headers | wc -l
}

# Function to get HPA metrics for a service
get_hpa_metrics() {
  local service=$1
  kubectl get hpa "$service-hpa" -n "$NAMESPACE" -o json 2>/dev/null || echo "{}"
}

# Function to log the current state
log_state() {
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  local service=$1
  local pod_count=$2
  local hpa_json=$3
  
  # Extract metrics from HPA
  local target_cpu=$(echo "$hpa_json" | jq -r '.spec.metrics[] | select(.resource.name=="cpu") | .resource.target.averageUtilization // 0')
  local current_cpu=$(echo "$hpa_json" | jq -r '.status.currentMetrics[] | select(.resource.name=="cpu") | .resource.current.averageUtilization // 0')
  local target_memory=$(echo "$hpa_json" | jq -r '.spec.metrics[] | select(.resource.name=="memory") | .resource.target.averageUtilization // 0')
  local current_memory=$(echo "$hpa_json" | jq -r '.status.currentMetrics[] | select(.resource.name=="memory") | .resource.current.averageUtilization // 0')
  local min_replicas=$(echo "$hpa_json" | jq -r '.spec.minReplicas // 1')
  local max_replicas=$(echo "$hpa_json" | jq -r '.spec.maxReplicas // 1')
  
  echo "[$timestamp] $service: Pods=$pod_count, CPU=$current_cpu/$target_cpu%, Memory=$current_memory/$target_memory%, Replicas=$min_replicas-$max_replicas" | tee -a "$LOG_FILE"
  
  # Update the results JSON
  jq --arg svc "$service" \
     --arg time "$timestamp" \
     --argjson pods "$pod_count" \
     --argjson targetCpu "$target_cpu" \
     --argjson currentCpu "$current_cpu" \
     --argjson targetMem "$target_memory" \
     --argjson currentMem "$current_memory" \
     --argjson minReplicas "$min_replicas" \
     --argjson maxReplicas "$max_replicas" \
     '.[$svc] = (.[$svc] // []) + [{
       "timestamp": $time,
       "pods": $pods,
       "cpu": {
         "target": $targetCpu,
         "current": $currentCpu
       },
       "memory": {
         "target": $targetMem,
         "current": $currentMem
       },
       "replicas": {
         "min": $minReplicas,
         "max": $maxReplicas
       }
     }]' "$RESULTS_FILE" > "${RESULTS_FILE}.tmp" && mv "${RESULTS_FILE}.tmp" "$RESULTS_FILE"
}

echo "Monitoring autoscaling for the following services: ${SERVICES[*]}"
echo "Namespace: $NAMESPACE"
echo "Duration: $DURATION seconds"
echo "Check interval: $CHECK_INTERVAL seconds"
echo "Log file: $LOG_FILE"
echo "Results file: $RESULTS_FILE"
echo "----------------------------------------"

# Initial state
echo "Initial state:"
for service in "${SERVICES[@]}"; do
  pod_count=$(get_pod_count "$service")
  hpa_json=$(get_hpa_metrics "$service")
  log_state "$service" "$pod_count" "$hpa_json"
done

echo "----------------------------------------"
echo "Starting monitoring..."

# Monitor for the specified duration
end_time=$(($(date +%s) + DURATION))
while [ $(date +%s) -lt $end_time ]; do
  for service in "${SERVICES[@]}"; do
    pod_count=$(get_pod_count "$service")
    hpa_json=$(get_hpa_metrics "$service")
    log_state "$service" "$pod_count" "$hpa_json"
  done
  
  echo "----------------------------------------"
  sleep "$CHECK_INTERVAL"
done

echo "Monitoring completed!"
echo "Log file: $LOG_FILE"
echo "Results file: $RESULTS_FILE"

# Generate a summary
echo "----------------------------------------"
echo "Summary:"
for service in "${SERVICES[@]}"; do
  initial_pods=$(jq -r --arg svc "$service" 'if .[$svc] and (.[$svc] | length > 0) then .[$svc][0].pods else "N/A" end' "$RESULTS_FILE")
  max_pods=$(jq -r --arg svc "$service" 'if .[$svc] and (.[$svc] | length > 0) then .[$svc] | max_by(.pods).pods else "N/A" end' "$RESULTS_FILE")
  final_pods=$(jq -r --arg svc "$service" 'if .[$svc] and (.[$svc] | length > 0) then .[$svc][-1].pods else "N/A" end' "$RESULTS_FILE")
  
  echo "$service: Initial=$initial_pods, Max=$max_pods, Final=$final_pods"
  
  if [ "$initial_pods" != "N/A" ] && [ "$max_pods" != "N/A" ] && [ "$initial_pods" -lt "$max_pods" ]; then
    echo "  ✅ Autoscaling worked! Pods increased from $initial_pods to $max_pods"
  elif [ "$initial_pods" != "N/A" ] && [ "$max_pods" != "N/A" ] && [ "$initial_pods" -eq "$max_pods" ]; then
    echo "  ⚠️ No scaling occurred. Consider increasing the load or checking HPA configuration."
  else
    echo "  ❌ Could not determine if autoscaling worked."
  fi
done

# Copy results to a more accessible location
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
FINAL_LOG="autoscaling_log_${TIMESTAMP}.txt"
FINAL_RESULTS="autoscaling_results_${TIMESTAMP}.json"

cp "$LOG_FILE" "$FINAL_LOG"
cp "$RESULTS_FILE" "$FINAL_RESULTS"

echo "----------------------------------------"
echo "Final logs saved to: $FINAL_LOG"
echo "Final results saved to: $FINAL_RESULTS" 