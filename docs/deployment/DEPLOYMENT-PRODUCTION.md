# Production Deployment Guide

This guide outlines the steps to make your Inspira Project deployment production-ready.

## 1. Push Actual Frontend Application to Container Registry

```bash
# Build the frontend application with production settings
cd frontend
npm run build

# Create a production-optimized Docker image
docker build -t inspiraproject/frontend:prod -f Dockerfile .

# Push to Docker Hub (or your preferred container registry)
docker push inspiraproject/frontend:prod

# Update the deployment to use this image
kubectl set image deployment/frontend frontend=inspiraproject/frontend:prod -n microservices
```

## 2. Configure SSL/TLS with Cert-Manager

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Create a ClusterIssuer for Let's Encrypt
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF

# Update your ingress to use TLS
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: inspira-ingress
  namespace: microservices
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/rewrite-target: /\$1
    nginx.ingress.kubernetes.io/use-regex: "true"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
  - hosts:
    - your-domain.com
    secretName: inspira-tls-cert
  rules:
  - host: your-domain.com
    http:
      paths:
      - path: /api/gateway/?(.*)
        pathType: Prefix
        backend:
          service:
            name: api-gateway
            port:
              number: 80
      - path: /api/users/?(.*)
        pathType: Prefix
        backend:
          service:
            name: user-service
            port:
              number: 80
      - path: /(.*)
        pathType: Prefix
        backend:
          service:
            name: frontend
            port:
              number: 80
EOF
```

## 3. Set Up Custom Domain

1. Purchase a domain from a domain registrar (e.g., GoDaddy, Namecheap, Google Domains)
2. Create a DNS A record pointing to your ingress IP address:
   - Type: A
   - Name: @ (or subdomain like 'app')
   - Value: 4.156.37.48 (your ingress IP)
   - TTL: 3600 (or as recommended)

## 4. Implement Monitoring and Logging

```bash
# Install Prometheus and Grafana for monitoring
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace

# Install ELK stack or Loki for logging
helm repo add elastic https://helm.elastic.co
helm repo update
helm install elasticsearch elastic/elasticsearch --namespace logging --create-namespace
helm install kibana elastic/kibana --namespace logging --create-namespace
helm install filebeat elastic/filebeat --namespace logging
```

## 5. Set Up Horizontal Pod Autoscaling

```bash
# Enable autoscaling for your deployments
kubectl autoscale deployment frontend --cpu-percent=80 --min=2 --max=10 -n microservices
kubectl autoscale deployment api-gateway --cpu-percent=80 --min=2 --max=10 -n microservices
kubectl autoscale deployment user-service --cpu-percent=80 --min=2 --max=10 -n microservices
```

## 6. Implement Resource Quotas

```bash
# Create a resource quota for the namespace
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: inspira-quota
  namespace: microservices
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
    pods: "20"
EOF
```

## 7. Set Up Backup and Disaster Recovery

```bash
# Install Velero for backup and restore
velero install \
    --provider azure \
    --plugins velero/velero-plugin-for-microsoft-azure:v1.6.0 \
    --bucket velero \
    --secret-file ./credentials-velero \
    --backup-location-config resourceGroup=inspira-project,storageAccount=inspirabackup,subscriptionId=your-subscription-id \
    --snapshot-location-config resourceGroup=inspira-project,subscriptionId=your-subscription-id

# Create a scheduled backup
velero schedule create daily-backup --schedule="0 1 * * *" --include-namespaces microservices
```

## 8. Implement Network Policies

```bash
# Create a network policy to restrict traffic
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-except-ingress
  namespace: microservices
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: microservices
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: microservices
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
    ports:
    - protocol: UDP
      port: 53
EOF
```

## 9. Set Up CI/CD Pipeline for Production

Enhance your GitHub Actions workflow to include:
- Separate staging and production environments
- Automated testing before deployment
- Canary deployments or blue-green deployments
- Automated rollbacks on failure

## 10. Security Hardening

- Implement Pod Security Policies
- Regular security scanning of container images
- Secret management with Azure Key Vault
- Regular security audits and penetration testing

## 11. Documentation and Runbooks

- Create comprehensive documentation for the production environment
- Develop runbooks for common operational tasks
- Document incident response procedures
- Set up on-call rotation and alerting 