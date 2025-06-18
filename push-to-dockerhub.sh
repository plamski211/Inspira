#!/bin/bash
# push-to-dockerhub.sh

# Set your Docker Hub username - use a public repository
DOCKER_USERNAME="plamennyagolov"

# Create a simple test image
echo "Building test image..."
mkdir -p test
cat > test/Dockerfile << EOF
FROM nginx:alpine
RUN echo "Inspira Test Image" > /usr/share/nginx/html/index.html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

cd test
docker build -t $DOCKER_USERNAME/inspira-test:latest .
docker push $DOCKER_USERNAME/inspira-test:latest
cd ..

# Create a Kubernetes deployment for the test image
cat > public-nginx-test.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: public-nginx-test
  namespace: microservices
spec:
  replicas: 1
  selector:
    matchLabels:
      app: public-nginx-test
  template:
    metadata:
      labels:
        app: public-nginx-test
    spec:
      containers:
      - name: nginx
        image: $DOCKER_USERNAME/inspira-test:latest
---
apiVersion: v1
kind: Service
metadata:
  name: public-nginx-test
  namespace: microservices
spec:
  selector:
    app: public-nginx-test
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF

echo "Test image pushed to Docker Hub and deployment manifest created"
echo "Apply the deployment with: kubectl apply -f public-nginx-test.yaml" 