# Docker Build Troubleshooting Guide

This guide explains common Docker build issues encountered in the CI/CD pipeline and how to fix them.

## Missing Dockerfile Error

### Issue

When running the Docker build step in GitHub Actions, you might encounter this error:

```
ERROR: failed to solve: failed to read dockerfile: open Dockerfile: no such file or directory
Error: buildx failed with: ERROR: failed to solve: failed to read dockerfile: open Dockerfile: no such file or directory
```

This happens when the Dockerfile for a service doesn't exist in the expected directory.

### Solution

Our CI/CD pipeline includes several mechanisms to handle this:

1. **Automatic Dockerfile Generation**: The pipeline automatically creates Dockerfiles for services if they don't exist.

2. **Verification Script**: A dedicated verification step specifically checks for the user-service Dockerfile.

3. **Fallback Mechanism**: If the generation script isn't found, a simple inline fallback is used.

## How to Fix Manually

If you need to create a Dockerfile manually:

### For Java Services (API Gateway, User Service, Content Service, Media Service)

Create a file named `Dockerfile` in the service directory with this content:

```dockerfile
FROM openjdk:17-jdk-slim
WORKDIR /app
COPY . .
EXPOSE 8080
CMD ["java", "-jar", "app.jar"]
```

For testing purposes, you may also need to create a dummy JAR file:

```bash
echo "dummy jar" > app.jar
```

### For Frontend

Create a file named `Dockerfile` in the frontend directory with this content:

```dockerfile
FROM nginx:alpine
COPY . /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

## Verification Scripts

We've created several scripts to help verify and fix Dockerfile issues:

1. `scripts/ci-cd/generate-dockerfiles.sh`: Generates Dockerfiles for all services if they don't exist.
2. `scripts/ci-cd/verify-user-service.sh`: Specifically verifies the user-service Dockerfile.

## Pipeline Resilience

Our CI/CD pipeline is designed to be resilient to missing Dockerfiles by:

1. Checking for Dockerfiles before building
2. Creating them if they don't exist
3. Using fallback mechanisms if the primary method fails
4. Providing detailed error messages and verification steps

This ensures that the pipeline can continue even if some components are missing, making it ideal for demonstration and learning purposes. 