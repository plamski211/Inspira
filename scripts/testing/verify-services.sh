#!/bin/bash

# Script to verify all Inspira microservices are working

INGRESS_IP=$(kubectl get ingress inspira-ingress -n microservices -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
API_GATEWAY_IP=$(kubectl get service api-gateway-external -n microservices -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)

echo "Verifying Inspira microservices..."
echo "=================================="
echo

# Function to check health endpoint
check_health() {
  local service=$1
  local url=$2
  
  echo -n "Checking $service... "
  response=$(curl -s "$url")
  
  if [[ $response == *"UP"* ]]; then
    echo "✅ UP"
    echo "  Response: $response"
  else
    echo "❌ DOWN"
    echo "  Response: $response"
  fi
}

# Check via ingress
echo "Checking services via Ingress ($INGRESS_IP):"
echo "-------------------------------------------"
check_health "API Gateway" "http://$INGRESS_IP/api/gateway/health.html"
check_health "User Service" "http://$INGRESS_IP/api/users/health.html"
check_health "Content Service" "http://$INGRESS_IP/api/content/health.html"
check_health "Media Service" "http://$INGRESS_IP/api/media/health.html"

# Check via direct service access
echo
echo "Checking direct service access:"
echo "------------------------------"
kubectl exec -it $(kubectl get pod -l app=api-gateway -n microservices -o jsonpath='{.items[0].metadata.name}') -n microservices -- curl -s user-service:80/health.html | grep -q "UP" && echo "✅ API Gateway -> User Service: Connected" || echo "❌ API Gateway -> User Service: Failed"
kubectl exec -it $(kubectl get pod -l app=api-gateway -n microservices -o jsonpath='{.items[0].metadata.name}') -n microservices -- curl -s content-service:80/health.html | grep -q "UP" && echo "✅ API Gateway -> Content Service: Connected" || echo "❌ API Gateway -> Content Service: Failed"
kubectl exec -it $(kubectl get pod -l app=api-gateway -n microservices -o jsonpath='{.items[0].metadata.name}') -n microservices -- curl -s media-service:80/health.html | grep -q "UP" && echo "✅ API Gateway -> Media Service: Connected" || echo "❌ API Gateway -> Media Service: Failed"

# Check database connectivity
echo
echo "Checking database connectivity:"
echo "------------------------------"
kubectl exec -it $(kubectl get pod -l app=user-service -n microservices -o jsonpath='{.items[0].metadata.name}') -n microservices -- nc -z -v postgres-users 5432 2>&1 | grep -q "open" && echo "✅ User Service -> Postgres: Connected" || echo "❌ User Service -> Postgres: Failed"
kubectl exec -it $(kubectl get pod -l app=content-service -n microservices -o jsonpath='{.items[0].metadata.name}') -n microservices -- nc -z -v postgres-content 5432 2>&1 | grep -q "open" && echo "✅ Content Service -> Postgres: Connected" || echo "❌ Content Service -> Postgres: Failed"
kubectl exec -it $(kubectl get pod -l app=media-service -n microservices -o jsonpath='{.items[0].metadata.name}') -n microservices -- nc -z -v postgres-media 5432 2>&1 | grep -q "open" && echo "✅ Media Service -> Postgres: Connected" || echo "❌ Media Service -> Postgres: Failed"

# Check MinIO connectivity
echo
echo "Checking MinIO connectivity:"
echo "--------------------------"
kubectl exec -it $(kubectl get pod -l app=content-service -n microservices -o jsonpath='{.items[0].metadata.name}') -n microservices -- nc -z -v minio 9000 2>&1 | grep -q "open" && echo "✅ Content Service -> MinIO: Connected" || echo "❌ Content Service -> MinIO: Failed"
kubectl exec -it $(kubectl get pod -l app=media-service -n microservices -o jsonpath='{.items[0].metadata.name}') -n microservices -- nc -z -v minio 9000 2>&1 | grep -q "open" && echo "✅ Media Service -> MinIO: Connected" || echo "❌ Media Service -> MinIO: Failed"

# Check external access
echo
echo "Checking external access:"
echo "-----------------------"
if [[ ! -z "$API_GATEWAY_IP" ]]; then
  check_health "API Gateway External" "http://$API_GATEWAY_IP/health.html"
else
  echo "❌ API Gateway External: No IP assigned yet"
fi

echo
echo "=================================="
echo "Verification complete!" 