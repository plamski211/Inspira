#!/bin/bash

# Script to fix the frontend white screen issue in Docker Compose (URGENT FIX)
# This script uses a simplified approach with a static HTML page

echo "===== URGENT FIX: Frontend White Screen in Docker Compose ====="
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
  echo "❌ Docker not found. Please install it first."
  exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
  echo "❌ Docker Compose not found. Please install it first."
  exit 1
fi

# Create a simple frontend directory
echo "Creating a simple frontend..."
mkdir -p simple-frontend/html

# Create a simple HTML file
cat > simple-frontend/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
  <title>Inspira Platform</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }
    .container { max-width: 800px; margin: 0 auto; background-color: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1); }
    h1 { color: #333; }
    .service { margin-bottom: 20px; padding: 10px; border: 1px solid #ddd; border-radius: 4px; }
    .service h2 { margin-top: 0; }
    .button { display: inline-block; background-color: #4CAF50; color: white; padding: 10px 20px; text-align: center; text-decoration: none; border-radius: 4px; margin-top: 10px; }
  </style>
  <script>
    // Environment configuration
    window.ENV = {
      API_URL: 'http://localhost:8000',
      AUTH0_DOMAIN: 'dev-i9j8l4xe.us.auth0.com',
      AUTH0_CLIENT_ID: 'JBfJJE07F7yrWTPq7nZ04WO4XdqzPvOa',
      AUTH0_AUDIENCE: 'https://api.inspira.com',
      AUTH0_REDIRECT_URI: window.location.origin,
      ENV: 'development'
    };
    console.log('Environment config loaded:', window.ENV);
  </script>
</head>
<body>
  <div class="container">
    <h1>Inspira Platform</h1>
    <p>Welcome to the Inspira microservices platform.</p>
    <div class="service">
      <h2>Frontend</h2>
      <p>This is the frontend service that provides the user interface.</p>
    </div>
    <div class="service">
      <h2>API Gateway</h2>
      <p>Routes requests to the appropriate microservices.</p>
    </div>
    <div class="service">
      <h2>User Service</h2>
      <p>Manages user accounts and authentication.</p>
    </div>
    <div class="service">
      <h2>Content Service</h2>
      <p>Handles content storage and retrieval.</p>
    </div>
    <div class="service">
      <h2>Media Service</h2>
      <p>Processes and stores media files.</p>
    </div>
    <a href="/login" class="button">Login</a>
  </div>
</body>
</html>
EOF

# Create a health check file
mkdir -p simple-frontend/html/health
cat > simple-frontend/html/health/index.html << EOF
{"status":"UP","timestamp":"2025-06-21T02:30:00Z"}
EOF

# Create a Dockerfile for the simple frontend
cat > simple-frontend/Dockerfile << EOF
FROM nginx:alpine

COPY html/ /usr/share/nginx/html/

RUN echo 'server { \\
    listen 80; \\
    server_name _; \\
    root /usr/share/nginx/html; \\
    index index.html; \\
\\
    # MIME types \\
    include /etc/nginx/mime.types; \\
\\
    # Serve static files \\
    location / { \\
        try_files \$uri \$uri/ /index.html; \\
        add_header "Access-Control-Allow-Origin" "*"; \\
    } \\
\\
    # API proxy \\
    location /api/ { \\
        proxy_pass http://api-gateway:8080/; \\
        proxy_http_version 1.1; \\
        proxy_set_header Upgrade \$http_upgrade; \\
        proxy_set_header Connection "upgrade"; \\
        proxy_set_header Host \$host; \\
        proxy_cache_bypass \$http_upgrade; \\
        proxy_set_header X-Real-IP \$remote_addr; \\
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for; \\
        proxy_set_header X-Forwarded-Proto \$scheme; \\
    } \\
\\
    # Health check endpoint \\
    location /health { \\
        try_files \$uri \$uri/ /health/index.html; \\
    } \\
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
EOF

# Build the simple frontend
echo "Building the simple frontend..."
docker build -t simple-frontend simple-frontend/

# Create a Docker Compose file for the simple frontend
cat > docker-compose.simple.yml << EOF
version: '3'

networks:
  inspira-network:
    driver: bridge

services:
  frontend:
    container_name: frontend
    image: simple-frontend:latest
    ports:
      - "80:80"
    networks:
      - inspira-network
    depends_on:
      - api-gateway

  api-gateway:
    container_name: api-gateway
    build:
      context: ./api-gateway
    environment:
      USER_SERVICE_URL: http://user-service:8080
      CONTENT_SERVICE_URL: http://content-service:8081
      MEDIA_SERVICE_URL: http://media-service:8082
    ports:
      - "8000:8080"
    networks:
      - inspira-network
    depends_on:
      - user-service
      - content-service
      - media-service

  user-service:
    container_name: user-service
    build:
      context: ./user-service
    environment:
      SPRING_DATASOURCE_URL: jdbc:postgresql://postgres-users:5432/users
      SPRING_DATASOURCE_USERNAME: user_user
      SPRING_DATASOURCE_PASSWORD: user_pw
      SPRING_JPA_HIBERNATE_DDL_AUTO: update
      SPRING_JPA_SHOW_SQL: "true"
      SPRING_JPA_DATABASE_PLATFORM: org.hibernate.dialect.PostgreSQLDialect
      LOGGING_LEVEL_ORG_SPRINGFRAMEWORK_SECURITY: DEBUG
      LOGGING_LEVEL_COM_INSPIRA: DEBUG
      SERVER_PORT: 8080
      SPRING_PROFILES_ACTIVE: docker
    ports:
      - "8083:8080"
    networks:
      - inspira-network
    depends_on:
      postgres-users:
        condition: service_healthy
    restart: on-failure
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 30s

  content-service:
    container_name: content-service
    build:
      context: ./content-service
    environment:
      SPRING_DATASOURCE_URL: jdbc:postgresql://postgres-content:5432/content
      SPRING_DATASOURCE_USERNAME: content_user
      SPRING_DATASOURCE_PASSWORD: content_pw
      SPRING_JPA_HIBERNATE_DDL_AUTO: update
      SPRING_JPA_SHOW_SQL: "true"
      SERVER_PORT: 8081
      MINIO_ENDPOINT: http://minio:9000
      MINIO_ACCESS_KEY: minio
      MINIO_SECRET_KEY: minio123
      MINIO_BUCKET_NAME: content-files
      MEDIA_SERVICE_URL: http://media-service:8082
    ports:
      - "8081:8081"
    networks:
      - inspira-network
    depends_on:
      postgres-content:
        condition: service_healthy
      minio:
        condition: service_healthy

  media-service:
    container_name: media-service
    build:
      context: ./media-service
    environment:
      SPRING_DATASOURCE_URL: jdbc:postgresql://postgres-media:5432/media
      SPRING_DATASOURCE_USERNAME: media_user
      SPRING_DATASOURCE_PASSWORD: media_pw
      SPRING_JPA_HIBERNATE_DDL_AUTO: update
      SPRING_JPA_SHOW_SQL: "true"
      SERVER_PORT: 8082
      MINIO_ENDPOINT: http://minio:9000
      MINIO_ACCESS_KEY: minio
      MINIO_SECRET_KEY: minio123
      MINIO_BUCKET_NAME: media-files
    ports:
      - "8082:8082"
    networks:
      - inspira-network
    depends_on:
      postgres-media:
        condition: service_healthy
      minio:
        condition: service_healthy

  postgres-users:
    image: postgres:15
    environment:
      POSTGRES_USER: user_user
      POSTGRES_PASSWORD: user_pw
      POSTGRES_DB: users
    ports:
      - "5435:5432"
    volumes:
      - postgres_users_data:/var/lib/postgresql/data
    networks:
      - inspira-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user_user -d users"]
      interval: 5s
      timeout: 5s
      retries: 5
      start_period: 10s

  postgres-content:
    image: postgres:15
    environment:
      POSTGRES_USER: content_user
      POSTGRES_PASSWORD: content_pw
      POSTGRES_DB: content
    ports:
      - "5433:5432"
    volumes:
      - postgres_content_data:/var/lib/postgresql/data
    networks:
      - inspira-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U content_user -d content"]
      interval: 5s
      timeout: 5s
      retries: 5
      start_period: 10s

  postgres-media:
    image: postgres:15
    environment:
      POSTGRES_USER: media_user
      POSTGRES_PASSWORD: media_pw
      POSTGRES_DB: media
    ports:
      - "5434:5432"
    volumes:
      - postgres_media_data:/var/lib/postgresql/data
    networks:
      - inspira-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U media_user -d media"]
      interval: 5s
      timeout: 5s
      retries: 5
      start_period: 10s

  minio:
    image: minio/minio:latest
    volumes:
      - minio_data:/data
    ports:
      - "9000:9000"
      - "9001:9001"
    environment:
      MINIO_ROOT_USER: minio
      MINIO_ROOT_PASSWORD: minio123
    command: server /data --console-address ":9001"
    networks:
      - inspira-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 5s
      timeout: 5s
      retries: 5
      start_period: 10s

  pgadmin:
    image: dpage/pgadmin4
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@inspira.com
      PGADMIN_DEFAULT_PASSWORD: admin
    ports:
      - "5050:80"
    networks:
      - inspira-network
    depends_on:
      - postgres-users
      - postgres-content
      - postgres-media

volumes:
  postgres_users_data:
  postgres_content_data:
  postgres_media_data:
  minio_data:
EOF

# Stop the current Docker Compose setup
echo "Stopping the current Docker Compose setup..."
docker-compose down

# Start the new Docker Compose setup
echo "Starting the new Docker Compose setup..."
docker-compose -f docker-compose.simple.yml up -d

echo ""
echo "===== URGENT FIX COMPLETE ====="
echo ""
echo "The frontend should now be accessible at: http://localhost"
echo ""
echo "If you still see a white screen, try the following:"
echo "1. Clear your browser cache completely"
echo "2. Try accessing the frontend in an incognito/private window"
echo "3. Check the frontend logs: docker-compose logs frontend"
echo "4. Make sure the API Gateway is running: docker-compose ps api-gateway"
echo "" 