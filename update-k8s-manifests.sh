#!/bin/bash
# update-k8s-manifests.sh

ACR_NAME=inspiraregistry20250617
TAG="latest"

# Create directory for updated manifests
mkdir -p k8s-azure

# Process each service's manifests
for SERVICE in content-service media-service frontend; do
  if [ -d "${SERVICE}/k8s" ]; then
    echo "Processing ${SERVICE} manifests..."
    
    # Copy and update manifests
    cp ${SERVICE}/k8s/*.yaml k8s-azure/
    
    # Replace image references
    sed -i '' "s|\${REGISTRY}/${SERVICE}:\${TAG}|${ACR_NAME}.azurecr.io/${SERVICE}:${TAG}|g" k8s-azure/deployment.yaml
    
    # Update environment variables for Azure services
    if [ "$SERVICE" == "content-service" ]; then
      sed -i '' "s|MINIO_ENDPOINT.*|AZURE_STORAGE_ACCOUNT: \"$STORAGE_ACCOUNT\"|g" k8s-azure/deployment.yaml
      sed -i '' "s|MINIO_ACCESS_KEY.*|AZURE_STORAGE_ACCOUNT_NAME: \"\$(STORAGE_ACCOUNT_NAME)\"|g" k8s-azure/deployment.yaml
      sed -i '' "s|MINIO_SECRET_KEY.*|AZURE_STORAGE_ACCOUNT_KEY: \"\$(STORAGE_ACCOUNT_KEY)\"|g" k8s-azure/deployment.yaml
      sed -i '' "s|MINIO_BUCKET_NAME.*|AZURE_STORAGE_CONTAINER_NAME: \"content-files\"|g" k8s-azure/deployment.yaml
    fi
    
    if [ "$SERVICE" == "media-service" ]; then
      sed -i '' "s|MINIO_ENDPOINT.*|AZURE_STORAGE_ACCOUNT: \"$STORAGE_ACCOUNT\"|g" k8s-azure/deployment.yaml
      sed -i '' "s|MINIO_ACCESS_KEY.*|AZURE_STORAGE_ACCOUNT_NAME: \"\$(STORAGE_ACCOUNT_NAME)\"|g" k8s-azure/deployment.yaml
      sed -i '' "s|MINIO_SECRET_KEY.*|AZURE_STORAGE_ACCOUNT_KEY: \"\$(STORAGE_ACCOUNT_KEY)\"|g" k8s-azure/deployment.yaml
      sed -i '' "s|MINIO_BUCKET_NAME.*|AZURE_STORAGE_CONTAINER_NAME: \"media-files\"|g" k8s-azure/deployment.yaml
    fi
  fi
done

# Create missing manifests for api-gateway and user-service
cat > k8s-azure/api-gateway-deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-gateway
  namespace: microservices
spec:
  replicas: 2
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
        image: ${ACR_NAME}.azurecr.io/api-gateway:${TAG}
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
        livenessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 10
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

cat > k8s-azure/user-service-deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
  namespace: microservices
spec:
  replicas: 2
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
        image: ${ACR_NAME}.azurecr.io/user-service:${TAG}
        ports:
        - containerPort: 8080
        env:
        - name: SPRING_DATASOURCE_URL
          valueFrom:
            secretKeyRef:
              name: db-secrets
              key: users-db-url
        - name: SPRING_DATASOURCE_USERNAME
          valueFrom:
            secretKeyRef:
              name: db-secrets
              key: users-db-user
        - name: SPRING_DATASOURCE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-secrets
              key: users-db-password
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
        livenessProbe:
          httpGet:
            path: /users/profiles/health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /users/profiles/health
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 10
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

# Create ingress controller
cat > k8s-azure/ingress.yaml << EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: inspira-ingress
  namespace: microservices
  annotations:
    kubernetes.io/ingress.class: azure/application-gateway
    appgw.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  rules:
  - host: inspira.example.com  # Replace with your actual domain
    http:
      paths:
      - path: /api/users
        pathType: Prefix
        backend:
          service:
            name: user-service
            port:
              number: 80
      - path: /api/content
        pathType: Prefix
        backend:
          service:
            name: content-service
            port:
              number: 80
      - path: /api/media
        pathType: Prefix
        backend:
          service:
            name: media-service
            port:
              number: 80
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend
            port:
              number: 80
EOF

echo "Kubernetes manifests updated in k8s-azure directory" 