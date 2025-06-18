#!/bin/bash
# update-to-public-images.sh - Script to update Kubernetes manifests to use public images

set -e

echo "Updating Kubernetes manifests to use public images..."

# Create directory for updated manifests if it doesn't exist
mkdir -p k8s-public

# Copy existing manifests
cp k8s-azure/*.yaml k8s-public/

# Update api-gateway deployment to use a public image
cat > k8s-public/api-gateway-deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-gateway
  namespace: microservices
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
        image: springcloud/spring-cloud-gateway:latest
        ports:
        - containerPort: 8080
        env:
        - name: USER_SERVICE_URL
          value: "http://user-service"
        - name: CONTENT_SERVICE_URL
          value: "http://content-service"
        - name: MEDIA_SERVICE_URL
          value: "http://media-service"
        resources:
          requests:
            cpu: 100m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 512Mi
---
apiVersion: v1
kind: Service
metadata:
  name: api-gateway
  namespace: microservices
spec:
  selector:
    app: api-gateway
  ports:
  - port: 80
    targetPort: 8080
  type: ClusterIP
EOF

# Update user-service deployment to use a public image
cat > k8s-public/user-service-deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
  namespace: microservices
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
        image: openjdk:17-slim
        command: ["java", "-jar", "/app/app.jar"]
        ports:
        - containerPort: 8080
        env:
        - name: SPRING_DATASOURCE_URL
          value: "jdbc:h2:mem:testdb"
        - name: SPRING_DATASOURCE_USERNAME
          value: "sa"
        - name: SPRING_DATASOURCE_PASSWORD
          value: ""
        - name: SPRING_JPA_HIBERNATE_DDL_AUTO
          value: "update"
        - name: SPRING_JPA_SHOW_SQL
          value: "false"
        - name: SERVER_PORT
          value: "8080"
        resources:
          requests:
            cpu: 200m
            memory: 512Mi
          limits:
            cpu: 1000m
            memory: 1Gi
---
apiVersion: v1
kind: Service
metadata:
  name: user-service
  namespace: microservices
spec:
  selector:
    app: user-service
  ports:
  - port: 80
    targetPort: 8080
  type: ClusterIP
EOF

# Update frontend deployment to use a public image
cat > k8s-public/frontend-deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: microservices
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
        image: nginx:latest
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: frontend
  namespace: microservices
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF

echo "Manifests updated in k8s-public directory"
echo "Apply with: kubectl apply -f k8s-public/" 