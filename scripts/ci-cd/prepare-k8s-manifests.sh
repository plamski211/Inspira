#!/bin/bash

# Script to prepare Kubernetes manifests for deployment

echo "===== Preparing Kubernetes Manifests ====="
echo ""

# Create k8s-azure directory if it doesn't exist
mkdir -p k8s-azure

# Check if base manifests exist
if [ -d "k8s/base" ]; then
  echo "Using existing base manifests as templates"
  
  # Copy base manifests to k8s-azure directory
  cp -f k8s/base/api-gateway-deployment.yaml k8s-azure/ 2>/dev/null || echo "No api-gateway-deployment.yaml found in base"
  cp -f k8s/base/frontend-deployment.yaml k8s-azure/ 2>/dev/null || echo "No frontend-deployment.yaml found in base"
  cp -f k8s/base/user-service-deployment.yaml k8s-azure/ 2>/dev/null || echo "No user-service-deployment.yaml found in base"
  cp -f k8s/base/content-service-deployment.yaml k8s-azure/ 2>/dev/null || echo "No content-service-deployment.yaml found in base"
  cp -f k8s/base/media-service-deployment.yaml k8s-azure/ 2>/dev/null || echo "No media-service-deployment.yaml found in base"
  cp -f k8s/base/config.yaml k8s-azure/ 2>/dev/null || echo "No config.yaml found in base"
  cp -f k8s/base/ingress.yaml k8s-azure/ 2>/dev/null || echo "No ingress.yaml found in base"
  
  echo "Base manifests copied to k8s-azure directory"
else
  echo "No base manifests found, creating simple manifests"
  
  # Create simple api-gateway-deployment.yaml
  cat > k8s-azure/api-gateway-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-gateway
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api-gateway
  template:
    metadata:
      labels:
        app: api-gateway
    spec:
      containers:
      - name: api-gateway
        image: inspira/api-gateway:latest
        ports:
        - containerPort: 8080
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: api-gateway
  namespace: default
spec:
  selector:
    app: api-gateway
  ports:
  - port: 8080
    targetPort: 8080
  type: ClusterIP
EOF

  # Create simple frontend-deployment.yaml
  cat > k8s-azure/frontend-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: inspira/frontend:latest
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: frontend
  namespace: default
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF

  # Create simple user-service-deployment.yaml
  cat > k8s-azure/user-service-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: user-service
  template:
    metadata:
      labels:
        app: user-service
    spec:
      containers:
      - name: user-service
        image: inspira/user-service:latest
        ports:
        - containerPort: 8080
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: user-service
  namespace: default
spec:
  selector:
    app: user-service
  ports:
  - port: 8080
    targetPort: 8080
  type: ClusterIP
EOF

  # Create simple content-service-deployment.yaml
  cat > k8s-azure/content-service-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: content-service
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: content-service
  template:
    metadata:
      labels:
        app: content-service
    spec:
      containers:
      - name: content-service
        image: inspira/content-service:latest
        ports:
        - containerPort: 8080
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: content-service
  namespace: default
spec:
  selector:
    app: content-service
  ports:
  - port: 8080
    targetPort: 8080
  type: ClusterIP
EOF

  # Create simple media-service-deployment.yaml
  cat > k8s-azure/media-service-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: media-service
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: media-service
  template:
    metadata:
      labels:
        app: media-service
    spec:
      containers:
      - name: media-service
        image: inspira/media-service:latest
        ports:
        - containerPort: 8080
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: media-service
  namespace: default
spec:
  selector:
    app: media-service
  ports:
  - port: 8080
    targetPort: 8080
  type: ClusterIP
EOF

  # Create simple ingress.yaml
  cat > k8s-azure/ingress.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: inspira-ingress
  namespace: default
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/rewrite-target: /$1
spec:
  rules:
  - host: inspira.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend
            port:
              number: 80
      - path: /api/gateway(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: api-gateway
            port:
              number: 8080
      - path: /api/users(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: user-service
            port:
              number: 8080
      - path: /api/content(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: content-service
            port:
              number: 8080
      - path: /api/media(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: media-service
            port:
              number: 8080
EOF

  # Create simple config.yaml
  cat > k8s-azure/config.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: inspira-config
  namespace: default
data:
  API_URL: "https://api.inspira.example.com"
  FRONTEND_URL: "https://inspira.example.com"
  ENABLE_MONITORING: "true"
  LOG_LEVEL: "info"
EOF

  echo "Simple manifests created in k8s-azure directory"
fi

echo ""
echo "===== Kubernetes Manifests Prepared ====="
echo "Manifests are ready in the k8s-azure directory"
echo ""
echo "You can now update image tags with:"
echo "sed -i 's|image: .*api-gateway.*|image: your-registry/api-gateway:tag|g' k8s-azure/api-gateway-deployment.yaml"
echo "sed -i 's|image: .*frontend.*|image: your-registry/frontend:tag|g' k8s-azure/frontend-deployment.yaml"
echo "sed -i 's|image: .*user-service.*|image: your-registry/user-service:tag|g' k8s-azure/user-service-deployment.yaml"
echo "sed -i 's|image: .*content-service.*|image: your-registry/content-service:tag|g' k8s-azure/content-service-deployment.yaml"
echo "sed -i 's|image: .*media-service.*|image: your-registry/media-service:tag|g' k8s-azure/media-service-deployment.yaml" 