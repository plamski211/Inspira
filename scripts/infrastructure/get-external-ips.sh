#!/bin/bash

# Script to get external IPs for Inspira microservices

echo "Fetching external IPs for Inspira microservices..."
echo "=================================================="
echo

# Get Ingress IP
INGRESS_IP=$(kubectl get ingress inspira-ingress -n microservices -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Ingress Controller: $INGRESS_IP"
echo

echo "External Service IPs:"
echo "--------------------"

# Get API Gateway external IP
API_GATEWAY_IP=$(kubectl get service api-gateway-external -n microservices -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
if [ -z "$API_GATEWAY_IP" ]; then
  API_GATEWAY_IP="<pending>"
fi
echo "API Gateway: $API_GATEWAY_IP"

# Get Frontend external IP
FRONTEND_IP=$(kubectl get service frontend-external -n microservices -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
if [ -z "$FRONTEND_IP" ]; then
  FRONTEND_IP="<pending>"
fi
echo "Frontend: $FRONTEND_IP"

# Get MinIO external IP
MINIO_IP=$(kubectl get service minio-external -n microservices -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
if [ -z "$MINIO_IP" ]; then
  MINIO_IP="<pending>"
fi
echo "MinIO: $MINIO_IP"

# Get Content Service external IP
CONTENT_IP=$(kubectl get service content-service-external -n microservices -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
if [ -z "$CONTENT_IP" ]; then
  CONTENT_IP="<pending>"
fi
echo "Content Service: $CONTENT_IP"

# Get Media Service external IP
MEDIA_IP=$(kubectl get service media-service-external -n microservices -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
if [ -z "$MEDIA_IP" ]; then
  MEDIA_IP="<pending>"
fi
echo "Media Service: $MEDIA_IP"

echo
echo "Access URLs:"
echo "-----------"
echo "Ingress (all services):"
echo "  HTTP: http://$INGRESS_IP/"
echo "  HTTPS: https://$INGRESS_IP/"
echo

if [ "$API_GATEWAY_IP" != "<pending>" ]; then
  echo "API Gateway:"
  echo "  HTTP: http://$API_GATEWAY_IP/"
  echo "  HTTPS: https://$API_GATEWAY_IP/"
fi

if [ "$FRONTEND_IP" != "<pending>" ]; then
  echo "Frontend:"
  echo "  HTTP: http://$FRONTEND_IP/"
  echo "  HTTPS: https://$FRONTEND_IP/"
fi

if [ "$MINIO_IP" != "<pending>" ]; then
  echo "MinIO:"
  echo "  API: http://$MINIO_IP:9000/"
  echo "  Console: http://$MINIO_IP:9001/"
fi

if [ "$CONTENT_IP" != "<pending>" ]; then
  echo "Content Service:"
  echo "  HTTP: http://$CONTENT_IP/"
  echo "  HTTPS: https://$CONTENT_IP/"
fi

if [ "$MEDIA_IP" != "<pending>" ]; then
  echo "Media Service:"
  echo "  HTTP: http://$MEDIA_IP/"
  echo "  HTTPS: https://$MEDIA_IP/"
fi

echo
echo "Test Endpoints:"
echo "--------------"
echo "Test Dashboard: http://$INGRESS_IP/test/"

echo
echo "=================================================="
echo "Note: If IPs are showing as <pending>, wait a few minutes and run this script again." 