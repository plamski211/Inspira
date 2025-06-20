#!/bin/bash
# validate-deployment.sh - Script to validate the deployment of Inspira microservices

set -e

echo "Validating Inspira microservices deployment..."

# Check if all pods are running
echo "Checking pod status..."
PODS_RUNNING=$(kubectl get pods -n microservices -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}')
PODS_NOT_RUNNING=$(kubectl get pods -n microservices -o jsonpath='{.items[?(@.status.phase!="Running")].metadata.name}')

if [ -z "$PODS_NOT_RUNNING" ]; then
  echo "✅ All pods are running"
else
  echo "⚠️ Some pods are not running:"
  kubectl get pods -n microservices | grep -v "Running"
fi

# Check if all services are available
echo -e "\nChecking service status..."
SERVICES=$(kubectl get services -n microservices -o jsonpath='{.items[*].metadata.name}')
echo "✅ Services available: $SERVICES"

# Check if ingress is configured
echo -e "\nChecking ingress status..."
INGRESS=$(kubectl get ingress -n microservices -o jsonpath='{.items[*].metadata.name}')
if [ -z "$INGRESS" ]; then
  echo "⚠️ No ingress configured"
else
  echo "✅ Ingress configured: $INGRESS"
fi

# Test connectivity between services
echo -e "\nTesting connectivity between services..."

# Create a temporary pod to test connectivity
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-connectivity
  namespace: microservices
spec:
  containers:
  - name: curl
    image: curlimages/curl
    command: ["sleep", "3600"]
  restartPolicy: Never
EOF

echo "Waiting for test pod to be ready..."
kubectl wait --for=condition=Ready pod/test-connectivity -n microservices --timeout=60s

# Test connectivity to each service
for SERVICE in api-gateway user-service frontend; do
  echo "Testing connectivity to $SERVICE..."
  if kubectl exec -n microservices test-connectivity -- curl -s --connect-timeout 5 http://$SERVICE > /dev/null; then
    echo "✅ Successfully connected to $SERVICE"
  else
    echo "⚠️ Failed to connect to $SERVICE"
  fi
done

# Clean up test pod
kubectl delete pod test-connectivity -n microservices

echo -e "\nDeployment validation complete!" 