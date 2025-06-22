# Build stage
FROM node:18-alpine AS build

# Set working directory
WORKDIR /app

# Copy package files first
COPY package*.json ./

# Install dependencies for Linux platform
RUN npm cache clean --force && \
    npm install --no-package-lock --platform=linux --arch=x64 && \
    npm rebuild esbuild

# Copy the rest of the application
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

# Build the application
RUN npm run build

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
