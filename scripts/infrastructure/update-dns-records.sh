#!/bin/bash

# Script to update DNS records for Inspira microservices external IPs
# This script uses Azure CLI to update DNS records in Azure DNS

# Configuration
RESOURCE_GROUP="inspira-project"
DNS_ZONE="inspira-project.com"

# Get external IPs
echo "Fetching external IPs..."
INGRESS_IP=$(kubectl get ingress inspira-ingress -n microservices -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
API_GATEWAY_IP=$(kubectl get service api-gateway-external -n microservices -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
FRONTEND_IP=$(kubectl get service frontend-external -n microservices -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
MINIO_IP=$(kubectl get service minio-external -n microservices -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "Error: Azure CLI is not installed. Please install it first."
    exit 1
fi

# Check if logged in to Azure
echo "Checking Azure login status..."
az account show &> /dev/null
if [ $? -ne 0 ]; then
    echo "Not logged in to Azure. Please login:"
    az login
fi

# Update DNS records
echo "Updating DNS records..."

# Update main domain record (A record)
if [ ! -z "$INGRESS_IP" ]; then
    echo "Updating main domain record to point to Ingress IP: $INGRESS_IP"
    az network dns record-set a delete -g $RESOURCE_GROUP -z $DNS_ZONE -n @ -y 2>/dev/null || true
    az network dns record-set a create -g $RESOURCE_GROUP -z $DNS_ZONE -n @ --ttl 3600
    az network dns record-set a add-record -g $RESOURCE_GROUP -z $DNS_ZONE -n @ -a $INGRESS_IP
    echo "Updated @ -> $INGRESS_IP"
else
    echo "Warning: Ingress IP not found. Skipping main domain record update."
fi

# Update API Gateway subdomain
if [ ! -z "$API_GATEWAY_IP" ]; then
    echo "Updating api subdomain record to point to API Gateway external IP: $API_GATEWAY_IP"
    az network dns record-set a delete -g $RESOURCE_GROUP -z $DNS_ZONE -n api -y 2>/dev/null || true
    az network dns record-set a create -g $RESOURCE_GROUP -z $DNS_ZONE -n api --ttl 3600
    az network dns record-set a add-record -g $RESOURCE_GROUP -z $DNS_ZONE -n api -a $API_GATEWAY_IP
    echo "Updated api.$DNS_ZONE -> $API_GATEWAY_IP"
else
    echo "Warning: API Gateway external IP not found. Skipping api subdomain record update."
fi

# Update Frontend subdomain
if [ ! -z "$FRONTEND_IP" ]; then
    echo "Updating app subdomain record to point to Frontend external IP: $FRONTEND_IP"
    az network dns record-set a delete -g $RESOURCE_GROUP -z $DNS_ZONE -n app -y 2>/dev/null || true
    az network dns record-set a create -g $RESOURCE_GROUP -z $DNS_ZONE -n app --ttl 3600
    az network dns record-set a add-record -g $RESOURCE_GROUP -z $DNS_ZONE -n app -a $FRONTEND_IP
    echo "Updated app.$DNS_ZONE -> $FRONTEND_IP"
else
    echo "Warning: Frontend external IP not found. Skipping app subdomain record update."
fi

# Update MinIO subdomain
if [ ! -z "$MINIO_IP" ]; then
    echo "Updating storage subdomain record to point to MinIO external IP: $MINIO_IP"
    az network dns record-set a delete -g $RESOURCE_GROUP -z $DNS_ZONE -n storage -y 2>/dev/null || true
    az network dns record-set a create -g $RESOURCE_GROUP -z $DNS_ZONE -n storage --ttl 3600
    az network dns record-set a add-record -g $RESOURCE_GROUP -z $DNS_ZONE -n storage -a $MINIO_IP
    echo "Updated storage.$DNS_ZONE -> $MINIO_IP"
else
    echo "Warning: MinIO external IP not found. Skipping storage subdomain record update."
fi

echo
echo "DNS records update completed."
echo
echo "Access URLs:"
echo "-----------"
echo "Main application: https://$DNS_ZONE/"
echo "API Gateway: https://api.$DNS_ZONE/"
echo "Frontend: https://app.$DNS_ZONE/"
echo "MinIO API: http://storage.$DNS_ZONE:9000/"
echo "MinIO Console: http://storage.$DNS_ZONE:9001/"
echo
echo "Note: DNS propagation may take some time (up to 24 hours)." 