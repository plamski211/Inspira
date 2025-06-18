#!/bin/bash
# fix-acr-auth.sh - Script to fix ACR authentication issues

set -e

echo "Creating service principal for ACR authentication..."
ACR_NAME=inspiraregistry20250617
ACR_REGISTRY_ID=$(az acr show --name $ACR_NAME --query id --output tsv)

# Create service principal and assign AcrPull role
echo "Creating service principal with AcrPull role..."
SP_PASSWORD=$(az ad sp create-for-rbac --name inspira-acr-service-principal --role AcrPull --scopes $ACR_REGISTRY_ID --query password --output tsv)
SP_APP_ID=$(az ad sp list --display-name inspira-acr-service-principal --query [].appId --output tsv)

echo "Service principal created:"
echo "App ID: $SP_APP_ID"
echo "Password: [HIDDEN]"

# Create Kubernetes secret with service principal credentials
echo "Creating Kubernetes secret with service principal credentials..."
kubectl create secret docker-registry acr-sp-secret \
  --namespace microservices \
  --docker-server=$ACR_NAME.azurecr.io \
  --docker-username=$SP_APP_ID \
  --docker-password=$SP_PASSWORD \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Secret created: acr-sp-secret"

# Update deployments to use the new secret
echo "Updating deployments to use the new secret..."
for DEPLOYMENT in api-gateway user-service frontend; do
  echo "Updating $DEPLOYMENT..."
  kubectl patch deployment $DEPLOYMENT -n microservices --patch '{"spec": {"template": {"spec": {"imagePullSecrets": [{"name": "acr-sp-secret"}]}}}}'
done

echo "Restarting deployments..."
kubectl rollout restart deployment -n microservices

echo "Done! Check pod status with: kubectl get pods -n microservices" 