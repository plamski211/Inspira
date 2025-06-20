FROM node:18-alpine AS build

# Set working directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Create env-config.js
RUN echo "// Environment configuration\n\
window.ENV = {\n\
  API_URL: '/api',\n\
  AUTH0_DOMAIN: 'dev-i9j8l4xe.us.auth0.com',\n\
  AUTH0_CLIENT_ID: 'JBfJJE07F7yrWTPq7nZ04WO4XdqzPvOa',\n\
  AUTH0_AUDIENCE: 'https://api.inspira.com',\n\
  AUTH0_REDIRECT_URI: window.location.origin,\n\
  ENV: 'production'\n\
};\n\
console.log('Environment config loaded:', window.ENV);" > ./public/env-config.js

# Build the application
RUN npm run build

# Stage 2: Serve with Nginx
FROM nginx:alpine

# Copy built assets
COPY --from=build /app/dist /usr/share/nginx/html

# Copy env-config.js to served directory
COPY --from=build /app/public/env-config.js /usr/share/nginx/html/env-config.js

# Create a proper nginx configuration with correct MIME types
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
        proxy_pass http://api-gateway;\n\
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

# Expose port
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
