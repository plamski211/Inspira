# Docker Compose Frontend Fixes

This document explains how to fix the white screen issues when running the application with Docker Compose.

## Problem

When running the application with Docker Compose, the frontend may display a white screen in various parts of the application:

1. After login
2. On profile pages
3. In other parts of the application

## Root Causes

1. **Incorrect Frontend Configuration**: The frontend was not properly configured to serve the application in Docker Compose.
2. **Missing Environment Configuration**: The `env-config.js` file was not properly mounted in the container.
3. **MIME Type Issues**: JavaScript and CSS files were not being served with the correct MIME types.
4. **API Gateway Connectivity**: The frontend was not properly configured to connect to the API Gateway.

## Solution

We've created a script (`scripts/deployment/fix-frontend-local.sh`) that:

1. Creates a proper `env-config.js` file with the correct configuration
2. Rebuilds the frontend container with a proper Nginx configuration
3. Configures the frontend to correctly connect to the API Gateway

### How to Fix

To fix the white screen issues, run:

```bash
./scripts/deployment/fix-frontend-local.sh
```

This script will:
- Create a proper `env-config.js` file
- Stop and remove the frontend container
- Rebuild the frontend container
- Start the frontend container

After running the script, the frontend should be accessible at http://localhost.

## Technical Details

### 1. Frontend Dockerfile

We've created a new Dockerfile (`frontend/Dockerfile.compose`) that:

- Uses a multi-stage build process
- Properly builds the frontend application
- Creates a fallback HTML if the build fails
- Configures Nginx to serve the application with proper MIME types
- Sets up proper API Gateway proxying

### 2. Nginx Configuration

We've created a proper Nginx configuration (`frontend/nginx.conf`) that:

- Serves the frontend application
- Configures proper MIME types for JavaScript and CSS files
- Sets up proper API Gateway proxying
- Creates a health check endpoint

### 3. Environment Configuration

We've created a proper environment configuration (`frontend/public/env-config.js`) that:

- Sets the API URL to `/api`
- Configures Auth0 for authentication
- Sets the environment to `development`

## Troubleshooting

If you're still seeing white screens after running the fix script, try:

1. **Clear Browser Cache**: Clear your browser cache to ensure you're getting the latest version of the application.
2. **Check Frontend Logs**: Run `docker-compose logs frontend` to check for any errors.
3. **Check API Gateway**: Make sure the API Gateway is running with `docker-compose ps api-gateway`.
4. **Check API Gateway Connectivity**: Try accessing the API Gateway directly with `curl http://localhost:8000/health`.
5. **Check Browser Console**: Open your browser's developer tools and check the console for any errors.

## Database Connection Issues

If you're experiencing database connection issues, make sure:

1. The PostgreSQL containers are running: `docker-compose ps postgres-users postgres-content postgres-media`
2. The services are configured to use the correct database URLs:
   - User Service: `jdbc:postgresql://postgres-users:5432/users`
   - Content Service: `jdbc:postgresql://postgres-content:5432/content`
   - Media Service: `jdbc:postgresql://postgres-media:5432/media`
3. The services are using the correct database credentials:
   - User Service: `user_user` / `user_pw`
   - Content Service: `content_user` / `content_pw`
   - Media Service: `media_user` / `media_pw`

If you need to connect to the databases using pgAdmin, use:
- Host: `localhost`
- Port: `5435` for User Service, `5433` for Content Service, `5434` for Media Service
- Username: `user_user` for User Service, `content_user` for Content Service, `media_user` for Media Service
- Password: `user_pw` for User Service, `content_pw` for Content Service, `media_pw` for Media Service
- Database: `users` for User Service, `content` for Content Service, `media` for Media Service 