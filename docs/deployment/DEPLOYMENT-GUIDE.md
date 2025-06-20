# Inspira Microservices Deployment Guide

This guide provides detailed instructions for deploying the Inspira microservices architecture on Azure Kubernetes Service (AKS).

## Prerequisites

- Azure CLI installed and configured
- kubectl installed and configured to connect to your AKS cluster
- Docker installed for building container images
- Access to Azure Container Registry (ACR) or Docker Hub

## Deployment Steps

### 1. Set up Kubernetes Namespace

```bash
kubectl create namespace microservices
```

### 2. Deploy Database Services

Deploy PostgreSQL databases for each service:

```bash
kubectl apply -f k8s-public/postgres-deployments.yaml
```

### 3. Deploy MinIO Object Storage

```bash
kubectl apply -f k8s-public/minio-deployment.yaml
```

### 4. Create Kubernetes Secrets

Create secrets for database credentials and MinIO access:

```bash
kubectl apply -f k8s-public/secrets.yaml
```

### 5. Deploy Microservices

Deploy all microservices:

```bash
kubectl apply -f k8s-public/api-gateway-deployment.yaml
kubectl apply -f k8s-public/user-service-deployment.yaml
kubectl apply -f k8s-public/content-service-deployment.yaml
kubectl apply -f k8s-public/media-service-deployment.yaml
kubectl apply -f k8s-public/frontend-deployment.yaml
```

### 6. Configure Ingress

Deploy the NGINX Ingress Controller and configure ingress rules:

```bash
kubectl apply -f k8s-public/ingress-tls.yaml
```

### 7. Configure Monitoring

Deploy Prometheus ServiceMonitors for each microservice:

```bash
kubectl apply -f k8s-public/service-monitors.yaml
```

### 8. Configure Autoscaling

Deploy Horizontal Pod Autoscalers for each microservice:

```bash
kubectl apply -f k8s-public/horizontal-pod-autoscalers.yaml
```

### 9. Apply Resource Quotas

```bash
kubectl apply -f k8s-public/resource-quota.yaml
```

### 10. Apply Network Policies

```bash
kubectl apply -f k8s-public/network-policy.yaml
```

### 11. Configure External Services

To expose services with dedicated external IPs:

```bash
kubectl apply -f k8s-public/external-services.yaml
```

This creates LoadBalancer services for:
- api-gateway-external: Direct access to the API Gateway
- frontend-external: Direct access to the frontend application
- minio-external: Direct access to MinIO storage API and console

## Accessing the Services

### Via Ingress Controller

All services are accessible through the Ingress controller at the following paths:

- Frontend: http://[INGRESS_IP]/
- API Gateway: http://[INGRESS_IP]/api/gateway/
- User Service: http://[INGRESS_IP]/api/users/
- Content Service: http://[INGRESS_IP]/api/content/
- Media Service: http://[INGRESS_IP]/api/media/

### Via External IPs

Some services are also directly accessible via their LoadBalancer external IPs:

```bash
kubectl get services -n microservices | grep external
```

- API Gateway: http://[API_GATEWAY_EXTERNAL_IP]/
- Frontend: http://[FRONTEND_EXTERNAL_IP]/
- MinIO API: http://[MINIO_EXTERNAL_IP]:9000/
- MinIO Console: http://[MINIO_EXTERNAL_IP]:9001/

## Troubleshooting

### Checking Pod Status

```bash
kubectl get pods -n microservices
```

### Checking Logs

```bash
kubectl logs -f [POD_NAME] -n microservices
```

### Checking Service Status

```bash
kubectl get services -n microservices
```

### Checking Ingress Status

```bash
kubectl describe ingress -n microservices
```

## Maintenance

### Updating Deployments

To update a deployment with a new image:

```bash
kubectl set image deployment/[DEPLOYMENT_NAME] [CONTAINER_NAME]=[NEW_IMAGE] -n microservices
```

### Scaling Services

To manually scale a deployment:

```bash
kubectl scale deployment [DEPLOYMENT_NAME] --replicas=[NUMBER] -n microservices
```

## CI/CD Integration

A GitHub Actions workflow is provided for automated deployments. See `.github/workflows/deploy-microservices.yml` for details.

To set up the required GitHub secrets:

```bash
./setup-github-secrets.sh
```

## Monitoring and Management

### Accessing Grafana Dashboard

```bash
./access-grafana.sh
```

Then visit http://localhost:3000 in your browser (credentials: admin/prom-operator).

### Checking Deployment Status

```bash
# Get pods
kubectl get pods -n microservices

# Get services
kubectl get services -n microservices

# Get ingress
kubectl get ingress -n microservices

# Get horizontal pod autoscalers
kubectl get hpa -n microservices
```

## Next Steps

1. **Custom Domain and SSL/TLS**:
   - Purchase a domain name
   - Set up DNS records
   - Install cert-manager and configure SSL/TLS

2. **Backup and Disaster Recovery**:
   - Implement Velero for backup and restore
   - Set up scheduled backups

3. **Security Enhancements**:
   - Implement proper authentication and authorization
   - Set up network policies for better security
   - Configure Azure Key Vault integration 