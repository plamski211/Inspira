FROM node:18-alpine AS build

# Set working directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies (use ci for clean install)
RUN npm ci || npm install

# Copy source code
COPY . .

# Create env-config.js if it doesn't exist
RUN if [ ! -f ./public/env-config.js ]; then \
    echo "// Environment configuration\n\
window.ENV = {\n\
  API_URL: '/api',\n\
  AUTH0_DOMAIN: 'dev-i9j8l4xe.us.auth0.com',\n\
  AUTH0_CLIENT_ID: 'JBfJJE07F7yrWTPq7nZ04WO4XdqzPvOa',\n\
  AUTH0_AUDIENCE: 'https://api.inspira.com',\n\
  AUTH0_REDIRECT_URI: window.location.origin,\n\
  ENV: 'production'\n\
};\n\
console.log('Environment config loaded:', window.ENV);" > ./public/env-config.js; \
fi

# Build the application (if it has a build script)
RUN npm run build || mkdir -p dist

# Create a simple index.html if build fails
RUN if [ ! -f ./dist/index.html ]; then \
    mkdir -p dist; \
    cat > ./dist/index.html << 'EOF'\
<!DOCTYPE html>\
<html>\
<head>\
  <title>Inspira Frontend</title>\
  <style>\
    body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }\
    .container { max-width: 800px; margin: 0 auto; background-color: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1); }\
    h1 { color: #333; }\
    .service { margin-bottom: 20px; padding: 10px; border: 1px solid #ddd; border-radius: 4px; }\
    .service h2 { margin-top: 0; }\
  </style>\
</head>\
<body>\
  <div class="container">\
    <h1>Inspira Platform</h1>\
    <p>Welcome to the Inspira microservices platform.</p>\
    <div class="service">\
      <h2>Frontend</h2>\
      <p>This is the frontend service that provides the user interface.</p>\
    </div>\
    <div class="service">\
      <h2>API Gateway</h2>\
      <p>Routes requests to the appropriate microservices.</p>\
    </div>\
    <div class="service">\
      <h2>User Service</h2>\
      <p>Manages user accounts and authentication.</p>\
    </div>\
    <div class="service">\
      <h2>Content Service</h2>\
      <p>Handles content storage and retrieval.</p>\
    </div>\
    <div class="service">\
      <h2>Media Service</h2>\
      <p>Processes and stores media files.</p>\
    </div>\
  </div>\
</body>\
</html>\
EOF\
; fi

# Copy env-config.js to dist directory if it exists
RUN if [ -f ./public/env-config.js ]; then \
    cp ./public/env-config.js ./dist/; \
fi

# Stage 2: Serve with Nginx
FROM nginx:alpine

# Copy built assets
COPY --from=build /app/dist/ /usr/share/nginx/html/

# Create nginx configuration with proper MIME types
RUN echo 'server {\n\
    listen 80;\n\
    server_name _;\n\
    root /usr/share/nginx/html;\n\
    index index.html;\n\
\n\
    # MIME types\n\
    include /etc/nginx/mime.types;\n\
\n\
    # Additional MIME type overrides\n\
    types {\n\
        application/javascript js;\n\
        text/css css;\n\
    }\n\
\n\
    # Serve static files\n\
    location / {\n\
        try_files $uri $uri/ /index.html;\n\
        add_header "Access-Control-Allow-Origin" "*";\n\
    }\n\
\n\
    # JavaScript files - explicitly set content type\n\
    location ~* \\.js$ {\n\
        add_header Content-Type "application/javascript";\n\
        try_files $uri =404;\n\
    }\n\
\n\
    # CSS files - explicitly set content type\n\
    location ~* \\.css$ {\n\
        add_header Content-Type "text/css";\n\
        try_files $uri =404;\n\
    }\n\
\n\
    # Asset files\n\
    location /assets/ {\n\
        try_files $uri =404;\n\
    }\n\
\n\
    # Handle API requests\n\
    location /api/ {\n\
        proxy_pass http://api-gateway:8080;\n\
        proxy_http_version 1.1;\n\
        proxy_set_header Upgrade $http_upgrade;\n\
        proxy_set_header Connection "upgrade";\n\
        proxy_set_header Host $host;\n\
        proxy_cache_bypass $http_upgrade;\n\
        proxy_set_header X-Real-IP $remote_addr;\n\
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\n\
        proxy_set_header X-Forwarded-Proto $scheme;\n\
    }\n\
}' > /etc/nginx/conf.d/default.conf

# Create a health check endpoint
RUN mkdir -p /usr/share/nginx/html/health && \
    echo '{"status":"UP","timestamp":"'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"}' > /usr/share/nginx/html/health/index.html

# Expose port
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
