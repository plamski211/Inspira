#!/bin/bash

# Script to generate Dockerfiles for services if they don't exist

echo "Checking and creating Dockerfiles if missing..."

# Check frontend
if [ ! -f "frontend/Dockerfile" ]; then
  echo "Creating simple Dockerfile for frontend"
  mkdir -p frontend
  cat > frontend/Dockerfile << 'EOF'
FROM nginx:alpine
COPY . /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF
  # Create a basic index.html
  cat > frontend/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
  <title>Inspira Frontend</title>
</head>
<body>
  <h1>Inspira Frontend Placeholder</h1>
  <p>This is a placeholder for the Inspira frontend service.</p>
</body>
</html>
EOF
fi

# Check API Gateway
if [ ! -f "api-gateway/Dockerfile" ]; then
  echo "Creating simple Dockerfile for API Gateway"
  mkdir -p api-gateway
  cat > api-gateway/Dockerfile << 'EOF'
FROM openjdk:17-jdk-slim
WORKDIR /app
COPY . .
EXPOSE 8080
CMD ["echo", "API Gateway placeholder"]
EOF
  # Create a basic file
  cat > api-gateway/app.txt << 'EOF'
This is a placeholder for the API Gateway service.
EOF
fi

# Check User Service
if [ ! -f "user-service/Dockerfile" ]; then
  echo "Creating simple Dockerfile for User Service"
  mkdir -p user-service
  cat > user-service/Dockerfile << 'EOF'
FROM openjdk:17-jdk-slim
WORKDIR /app
COPY . .
EXPOSE 8080
CMD ["java", "-jar", "app.jar"]
EOF
  # Create a basic file
  cat > user-service/app.txt << 'EOF'
This is a placeholder for the User Service.
EOF
  # Create a dummy JAR file to prevent errors
  echo "Creating dummy JAR file for User Service"
  echo "dummy jar" > user-service/app.jar
fi

# Check Content Service
if [ ! -f "content-service/Dockerfile" ]; then
  echo "Creating simple Dockerfile for Content Service"
  mkdir -p content-service
  cat > content-service/Dockerfile << 'EOF'
FROM openjdk:17-jdk-slim
WORKDIR /app
COPY . .
EXPOSE 8080
CMD ["echo", "Content Service placeholder"]
EOF
  # Create a basic file
  cat > content-service/app.txt << 'EOF'
This is a placeholder for the Content Service.
EOF
fi

# Check Media Service
if [ ! -f "media-service/Dockerfile" ]; then
  echo "Creating simple Dockerfile for Media Service"
  mkdir -p media-service
  cat > media-service/Dockerfile << 'EOF'
FROM openjdk:17-jdk-slim
WORKDIR /app
COPY . .
EXPOSE 8080
CMD ["echo", "Media Service placeholder"]
EOF
  # Create a basic file
  cat > media-service/app.txt << 'EOF'
This is a placeholder for the Media Service.
EOF
fi

echo "Dockerfile generation completed." 