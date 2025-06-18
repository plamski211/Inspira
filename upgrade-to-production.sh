#!/bin/bash

# Script to upgrade the Inspira Project deployment to production-ready status
# Usage: ./upgrade-to-production.sh <domain-name> <email>

set -e

# Check for required arguments
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <domain-name> <email>"
    echo "Example: $0 inspira-project.com admin@example.com"
    exit 1
fi

DOMAIN=$1
EMAIL=$2
INGRESS_IP=$(kubectl get ingress -n microservices -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')

echo "==== Upgrading Inspira Project to Production ===="
echo "Domain: $DOMAIN"
echo "Email: $EMAIL"
echo "Ingress IP: $INGRESS_IP"
echo ""

# Install Helm if not already installed
if ! command -v helm &> /dev/null; then
    echo "Installing Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# Create namespaces
echo "Creating namespaces..."
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace logging --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace cert-manager --dry-run=client -o yaml | kubectl apply -f -

# Install cert-manager
echo "Installing cert-manager..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
echo "Waiting for cert-manager to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/cert-manager -n cert-manager
kubectl wait --for=condition=available --timeout=300s deployment/cert-manager-webhook -n cert-manager

# Create ClusterIssuer
echo "Creating Let's Encrypt ClusterIssuer..."
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: $EMAIL
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF

# Update ingress with TLS
echo "Updating ingress with TLS configuration..."
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
    - $DOMAIN
    secretName: inspira-tls-cert
  rules:
  - host: $DOMAIN
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

# Install monitoring
echo "Installing Prometheus and Grafana..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace

# Set up autoscaling
echo "Setting up horizontal pod autoscaling..."
kubectl autoscale deployment frontend --cpu-percent=80 --min=2 --max=10 -n microservices
kubectl autoscale deployment api-gateway --cpu-percent=80 --min=2 --max=10 -n microservices
kubectl autoscale deployment user-service --cpu-percent=80 --min=2 --max=10 -n microservices

# Create resource quota
echo "Creating resource quota..."
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

# Create network policy
echo "Creating network policy..."
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

echo ""
echo "==== Production Upgrade Complete ===="
echo ""
echo "Next steps:"
echo "1. Update your DNS provider with an A record for $DOMAIN pointing to $INGRESS_IP"
echo "2. Wait for DNS propagation and SSL certificate issuance (may take up to 24 hours)"
echo "3. Build and push your actual frontend application image"
echo "4. Update the frontend deployment to use your production image"
echo ""
echo "Monitoring dashboard will be available at:"
echo "kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring"
echo "Then visit http://localhost:3000 (default credentials: admin/prom-operator)" 