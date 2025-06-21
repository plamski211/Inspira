# Frontend Deployment Solutions

This document provides comprehensive solutions for deploying the Inspira frontend application in different environments.

## Common Issues

The frontend application may display white screens due to several issues:

1. **MIME Type Configuration**: Incorrect MIME type configuration in Nginx can prevent JavaScript and CSS files from loading properly.
2. **SPA Routing**: Single Page Applications (SPA) like React require proper server configuration to handle client-side routing.
3. **API Gateway Integration**: The frontend needs proper configuration to communicate with the API Gateway.
4. **Environment Variables**: Missing or incorrect environment variables can cause the application to fail.
5. **Build Process**: Improper build process can result in missing or incorrect files in the production build.

## Docker Compose Solution

### Quick Fix

For a quick fix to the Docker Compose environment, run:

```bash
./scripts/deployment/fix-docker-compose-urgent.sh
```

This script deploys a simple static HTML page as a temporary solution.

### Proper Solution

For a complete solution that deploys the actual React application:

```bash
./scripts/deployment/fix-docker-compose-frontend-proper.sh
```

This script:

1. Creates a proper multi-stage Dockerfile (`Dockerfile.compose`) that:
   - Builds the React application with Node.js
   - Uses Nginx to serve the built files
   - Includes proper MIME type configuration
   - Sets up routing for SPA

2. Configures Nginx properly to:
   - Serve static assets with correct MIME types
   - Handle SPA routing by redirecting to index.html
   - Proxy API requests to the API Gateway
   - Include health check endpoints

3. Creates a complete Docker Compose configuration with all necessary services.

## Azure Kubernetes Solution

### Quick Fix

For a quick fix to the Azure Kubernetes deployment, run:

```bash
./scripts/deployment/fix-azure-frontend-urgent.sh
```

This script deploys a simple static HTML page as a temporary solution.

For an even simpler solution, run:

```bash
./scripts/deployment/fix-azure-simplest.sh
```

### Proper Solution

For a complete solution that deploys the actual React application to Azure Kubernetes:

```bash
./scripts/deployment/fix-azure-frontend-proper.sh
```

This script:

1. Creates a proper multi-stage Dockerfile for Azure that:
   - Builds the React application with Node.js
   - Uses Nginx to serve the built files
   - Includes proper MIME type configuration
   - Sets up routing for SPA

2. Configures Nginx properly to:
   - Serve static assets with correct MIME types
   - Handle SPA routing by redirecting to index.html
   - Proxy API requests to the API Gateway
   - Include health check endpoints

3. Creates Kubernetes deployment files with:
   - Proper resource limits
   - Health checks
   - Service configuration

4. Provides a script to build, push, and deploy the application to Azure Kubernetes.

## Manual Configuration

### Nginx Configuration

The key to fixing the white screen issues is proper Nginx configuration:

```nginx
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

    # React app - serve index.html for any path
    location / {
        try_files $uri $uri/ /index.html;
        add_header Cache-Control "no-store, no-cache, must-revalidate";
    }

    # API forwarding
    location /api/ {
        proxy_pass http://api-gateway:8080/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

### Environment Variables

Make sure the frontend has access to the correct environment variables:

```javascript
// env-config.js
window.ENV = {
  API_URL: 'http://localhost/api',
  AUTH_ENABLED: false,
  VERSION: '1.0.0'
};
```

## Troubleshooting

If you still encounter issues:

1. **Check Browser Console**: Open the browser developer tools (F12) to see any JavaScript errors.
2. **Check CORS**: Ensure CORS is properly configured in the API Gateway.
3. **Check Network Requests**: Use the Network tab in browser developer tools to see if requests are failing.
4. **Container Logs**: Check the logs of the frontend container:
   ```bash
   docker-compose logs frontend
   # or
   kubectl logs deployment/frontend
   ```
5. **Clear Browser Cache**: Sometimes issues persist due to cached resources.

## Additional Resources

- [React Deployment Best Practices](https://create-react-app.dev/docs/deployment/)
- [Nginx Configuration for React Apps](https://www.nginx.com/blog/deploying-nginx-plus-as-an-api-gateway-part-1/)
- [Kubernetes Deployment Strategies](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) 