# Build stage
FROM node:18-alpine AS build

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Clear npm cache and remove any existing node_modules
RUN npm cache clean --force && \
    rm -rf node_modules

# Install dependencies with clean slate
RUN npm install --no-package-lock --legacy-peer-deps

# Rebuild esbuild to match versions
RUN npm rebuild esbuild

# Copy source code
COPY . .

# Create env-config.js
RUN echo "window.ENV = { \
  API_URL: '/api', \
  AUTH0_DOMAIN: 'dev-i9j8l4xe.us.auth0.com', \
  AUTH0_CLIENT_ID: 'JBfJJE07F7yrWTPq7nZ04WO4XdqzPvOa', \
  AUTH0_AUDIENCE: 'https://api.inspira.com', \
  AUTH0_REDIRECT_URI: window.location.origin, \
  ENV: 'production' \
};" > ./public/env-config.js

# Build the application with increased memory limit
RUN NODE_OPTIONS="--max-old-space-size=4096" npm run build

# Stage 2: Serve with Nginx
FROM nginx:alpine

# Copy built assets
COPY --from=build /app/dist /usr/share/nginx/html
COPY --from=build /app/public/env-config.js /usr/share/nginx/html/env-config.js

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Create health check endpoint
RUN echo '{"status":"UP"}' > /usr/share/nginx/html/health.json

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
