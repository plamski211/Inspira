#!/bin/bash
# update-deployment.sh - Script to update the Inspira microservices deployment

set -e

# Define variables
NAMESPACE="microservices"
INGRESS_NAMESPACE="ingress-basic"

# Display help message
show_help() {
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  -h, --help                 Show this help message"
  echo "  -u, --update-images        Update container images"
  echo "  -r, --restart-services     Restart all services"
  echo "  -i, --update-ingress       Update ingress configuration"
  echo "  -m, --update-monitoring    Update monitoring configuration"
  echo ""
  echo "Examples:"
  echo "  $0 --update-images         # Update all container images"
  echo "  $0 --restart-services      # Restart all services"
  echo "  $0 --update-ingress        # Update ingress configuration"
}

# Update container images
update_images() {
  echo "Updating container images..."
  
  # Apply the latest manifests
  kubectl apply -f k8s-public/
  
  # Restart deployments to pick up new images
  kubectl rollout restart deployment -n $NAMESPACE
  
  echo "Container images updated successfully."
}

# Restart all services
restart_services() {
  echo "Restarting all services..."
  
  kubectl rollout restart deployment -n $NAMESPACE
  
  echo "Services restarted successfully."
}

# Update ingress configuration
update_ingress() {
  echo "Updating ingress configuration..."
  
  # Apply the latest ingress configuration
  kubectl apply -f k8s-public/ingress.yaml
  
  # Get the ingress IP
  INGRESS_IP=$(kubectl get service nginx-ingress-ingress-nginx-controller -n $INGRESS_NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  
  echo "Ingress configuration updated successfully."
  echo "Ingress IP: $INGRESS_IP"
}

# Update monitoring configuration
update_monitoring() {
  echo "Updating monitoring configuration..."
  
  # Check if monitoring addon is enabled
  MONITORING_ENABLED=$(az aks show --resource-group inspira-project --name inspira-aks --query addonProfiles.omsagent.enabled -o tsv)
  
  if [ "$MONITORING_ENABLED" == "true" ]; then
    echo "Monitoring is already enabled."
  else
    echo "Enabling monitoring addon..."
    az aks enable-addons --resource-group inspira-project --name inspira-aks --addons monitoring
  fi
  
  echo "Monitoring configuration updated successfully."
}

# Parse command line arguments
if [ $# -eq 0 ]; then
  show_help
  exit 0
fi

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      show_help
      exit 0
      ;;
    -u|--update-images)
      update_images
      shift
      ;;
    -r|--restart-services)
      restart_services
      shift
      ;;
    -i|--update-ingress)
      update_ingress
      shift
      ;;
    -m|--update-monitoring)
      update_monitoring
      shift
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      exit 1
      ;;
  esac
done

echo "Deployment update completed." 