# Azure Deployment Fixes

This document explains the fixes for two critical issues in the Azure deployment of the Inspira platform:

1. Frontend White Screen Issue
2. User Service Database Connection Issue

## 1. Frontend White Screen Issue

### Problem

When accessing the public Azure IP, the frontend displays a white screen instead of the fully working frontend application.

### Root Causes

1. **Improper Configuration**: The frontend was not properly configured to serve the application in the Azure environment.
2. **Missing Environment Configuration**: The `env-config.js` file was not properly mounted in the container.
3. **MIME Type Issues**: JavaScript and CSS files were not being served with the correct MIME types.

### Solution

We created a script (`scripts/deployment/fix-frontend-azure.sh`) that:

1. Creates a ConfigMap with the proper environment configuration
2. Deploys the frontend with the correct configuration
3. Mounts the environment configuration file in the container
4. Sets up proper health and readiness probes
5. Configures the service as a LoadBalancer to expose it externally

To fix the issue, run:

```bash
./scripts/deployment/fix-frontend-azure.sh
```

This script will:
- Create a ConfigMap with the proper environment configuration
- Deploy the frontend with the correct configuration
- Delete any existing pods to force a new deployment
- Wait for the deployment to be ready
- Display the frontend URL

## 2. User Service Database Connection Issue

### Problem

When running `docker-compose up`, the user service throws a connection error to the database, preventing user data from being saved.

### Root Causes

1. **Missing Database Configuration**: The user service was missing some required database configuration parameters.
2. **Connection Issues**: The user service was not properly configured to wait for the database to be ready.
3. **Restart Policy**: The user service was not configured to restart on failure.

### Solution

We updated the `docker-compose.yml` file to:

1. Add the PostgreSQL dialect configuration to ensure proper SQL generation
2. Add a restart policy to ensure the service restarts on failure
3. Add a healthcheck to ensure the service is properly running
4. Add the `docker` profile to ensure proper configuration in the Docker environment

The changes include:

```yaml
user-service:
  # ... existing configuration ...
  environment:
    # ... existing environment variables ...
    SPRING_JPA_DATABASE_PLATFORM: org.hibernate.dialect.PostgreSQLDialect
    SPRING_PROFILES_ACTIVE: docker
  restart: on-failure
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
    interval: 10s
    timeout: 5s
    retries: 3
    start_period: 30s
```

To apply these changes, simply run:

```bash
docker-compose down
docker-compose up -d
```

## Verification

### Frontend

To verify that the frontend is working correctly:

1. Access the frontend URL provided by the fix script
2. Check that the application loads correctly
3. Verify that you can interact with the application
4. Check the browser console for any errors

### User Service

To verify that the user service is working correctly:

1. Run `docker-compose ps` to check that all services are running
2. Check the user service logs with `docker-compose logs user-service`
3. Try to log in to the application and verify that user data is saved
4. Check the database with pgAdmin to verify that user data is being stored

## Troubleshooting

### Frontend Issues

If you're still experiencing issues with the frontend:

1. Check the frontend logs: `kubectl logs deployment/frontend`
2. Check if the API Gateway is accessible from the frontend
3. Check the browser console for any errors
4. Run the check-frontend script: `./scripts/deployment/check-frontend.sh`

### User Service Issues

If you're still experiencing issues with the user service:

1. Check the user service logs: `docker-compose logs user-service`
2. Check if the database is accessible: `docker-compose exec postgres-users pg_isready -U user_user -d users`
3. Check if the database has the correct schema: `docker-compose exec postgres-users psql -U user_user -d users -c "\dt"`
4. Try restarting the user service: `docker-compose restart user-service` 