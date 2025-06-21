#!/bin/bash

# Script to properly deploy the React frontend in Docker Compose

echo "===== PROPER FIX: Frontend White Screen in Docker Compose ====="
echo ""

# Create a proper Dockerfile for Docker Compose
cat <<EOF > frontend/Dockerfile.compose
# Build stage
FROM node:18-alpine as build

WORKDIR /app

# Copy package files and install dependencies
COPY package.json package-lock.json ./
RUN npm ci

# Copy the rest of the application code
COPY . .

# Build the application
RUN npm run build

# Production stage
FROM nginx:alpine

# Copy the build output to replace the default nginx contents
COPY --from=build /app/dist /usr/share/nginx/html

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Create a simple health check endpoint
RUN mkdir -p /usr/share/nginx/html/health && \
    echo "OK" > /usr/share/nginx/html/health/index.html

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
EOF

# Create a proper nginx.conf file
cat <<EOF > frontend/nginx.conf
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    # MIME types
    include /etc/nginx/mime.types;
    types {
        application/javascript js;
        text/css css;
    }

    # Health check endpoint
    location /health {
        access_log off;
        add_header Content-Type text/plain;
        return 200 'OK';
    }

    # API forwarding
    location /api/ {
        proxy_pass http://api-gateway:8080/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    # React app - serve index.html for any path
    location / {
        try_files \$uri \$uri/ /index.html;
        add_header Cache-Control "no-store, no-cache, must-revalidate";
    }

    # Static assets caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 30d;
        add_header Cache-Control "public, max-age=2592000";
        access_log off;
    }

    # Error handling
    error_page 404 /index.html;
    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }
}
EOF

# Create a proper docker-compose.yml file with the frontend service
cat <<EOF > docker-compose.frontend.yml
version: '3.8'

services:
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile.compose
    container_name: frontend
    ports:
      - "80:80"
    networks:
      - inspira-network
    depends_on:
      - api-gateway
    restart: unless-stopped

  api-gateway:
    image: inspira/api-gateway:latest
    container_name: api-gateway
    ports:
      - "8080:8080"
    networks:
      - inspira-network
    depends_on:
      - user-service
      - content-service
      - media-service
    environment:
      - SPRING_PROFILES_ACTIVE=docker
    restart: unless-stopped

  user-service:
    image: inspira/user-service:latest
    container_name: user-service
    networks:
      - inspira-network
    depends_on:
      postgres-users:
        condition: service_healthy
    environment:
      - SPRING_DATASOURCE_URL=jdbc:postgresql://postgres-users:5432/users
      - SPRING_DATASOURCE_USERNAME=postgres
      - SPRING_DATASOURCE_PASSWORD=postgres
    restart: unless-stopped

  content-service:
    image: inspira/content-service:latest
    container_name: content-service
    networks:
      - inspira-network
    depends_on:
      postgres-content:
        condition: service_healthy
      minio:
        condition: service_healthy
    environment:
      - SPRING_DATASOURCE_URL=jdbc:postgresql://postgres-content:5432/content
      - SPRING_DATASOURCE_USERNAME=postgres
      - SPRING_DATASOURCE_PASSWORD=postgres
      - MINIO_ENDPOINT=http://minio:9000
    restart: unless-stopped

  media-service:
    image: inspira/media-service:latest
    container_name: media-service
    networks:
      - inspira-network
    depends_on:
      postgres-media:
        condition: service_healthy
    environment:
      - SPRING_DATASOURCE_URL=jdbc:postgresql://postgres-media:5432/media
      - SPRING_DATASOURCE_USERNAME=postgres
      - SPRING_DATASOURCE_PASSWORD=postgres
    restart: unless-stopped

  postgres-users:
    image: postgres:15
    container_name: postgres-users
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=users
    ports:
      - "5435:5432"
    volumes:
      - postgres-users-data:/var/lib/postgresql/data
    networks:
      - inspira-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  postgres-content:
    image: postgres:15
    container_name: postgres-content
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=content
    ports:
      - "5433:5432"
    volumes:
      - postgres-content-data:/var/lib/postgresql/data
    networks:
      - inspira-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  postgres-media:
    image: postgres:15
    container_name: postgres-media
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=media
    ports:
      - "5434:5432"
    volumes:
      - postgres-media-data:/var/lib/postgresql/data
    networks:
      - inspira-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  minio:
    image: minio/minio
    container_name: minio
    command: server /data --console-address ":9001"
    ports:
      - "9000:9000"
      - "9001:9001"
    environment:
      - MINIO_ROOT_USER=minioadmin
      - MINIO_ROOT_PASSWORD=minioadmin
    volumes:
      - minio-data:/data
    networks:
      - inspira-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 10s
      timeout: 5s
      retries: 5

  pgadmin:
    image: dpage/pgadmin4
    container_name: pgadmin
    environment:
      - PGADMIN_DEFAULT_EMAIL=admin@inspira.com
      - PGADMIN_DEFAULT_PASSWORD=admin
    ports:
      - "5050:80"
    networks:
      - inspira-network
    depends_on:
      - postgres-users
      - postgres-content
      - postgres-media

networks:
  inspira-network:
    driver: bridge

volumes:
  postgres-users-data:
  postgres-content-data:
  postgres-media-data:
  minio-data:
EOF

echo "Files created successfully."
echo ""
echo "To build and run the frontend with Docker Compose, run:"
echo "docker-compose -f docker-compose.frontend.yml up -d --build frontend"
echo ""
echo "Would you like to build and run the frontend now? (y/n)"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  echo "Stopping any existing Docker Compose services..."
  docker-compose down

  echo "Building and running the frontend with Docker Compose..."
  docker-compose -f docker-compose.frontend.yml up -d --build frontend
  
  echo "Frontend should now be accessible at: http://localhost"
  echo "If you still see a white screen, try clearing your browser cache or accessing in an incognito window."
else
  echo "Deployment skipped. You can deploy manually using the instructions above."
fi

echo ""
echo "===== PROPER FIX COMPLETE =====" 