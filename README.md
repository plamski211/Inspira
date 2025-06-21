# Inspira Platform

This repository contains the Inspira Platform, a microservices-based application deployed to Azure Kubernetes Service (AKS).

## Architecture

The platform consists of the following microservices:

- **Frontend**: React-based web application
- **API Gateway**: Spring Boot application that routes requests to the appropriate microservices
- **User Service**: Spring Boot application that manages user accounts and authentication
- **Content Service**: Spring Boot application that handles content storage and retrieval
- **Media Service**: Spring Boot application that processes and stores media files

## Deployment

The platform is deployed to Azure Kubernetes Service (AKS) using a CI/CD pipeline. For detailed deployment instructions, see the following documentation:

- [Deployment Guide](docs/deployment/DEPLOYMENT-GUIDE.md)
- [Azure Deployment](docs/deployment/AZURE-DEPLOYMENT.md)
- [Production Deployment](docs/deployment/DEPLOYMENT-PRODUCTION.md)
- [Frontend Deployment](docs/deployment/FRONTEND-DEPLOYMENT.md)
- [Azure Deployment Fixes](docs/deployment/AZURE-DEPLOYMENT-FIXES.md) - Fixes for critical deployment issues
- [Docker Compose Fixes](docs/deployment/DOCKER-COMPOSE-FIXES.md) - Fixes for Docker Compose white screen issues
- [Urgent Fixes](docs/deployment/URGENT-FIXES.md) - **NEW**: Urgent fixes for white screen issues

## CI/CD Pipeline

The project uses GitHub Actions for continuous integration and continuous deployment, with automated testing and deployment to Azure Kubernetes Service (AKS).

### Pipeline Stages

1. **Code Quality**
   - ESLint for code linting
   - Prettier for code formatting
   - Runs on every push and pull request

2. **Tests**
   - Unit tests with Vitest
   - Integration tests
   - Test coverage reporting (minimum 80% coverage required)

3. **Security Scan**
   - Trivy vulnerability scanner
   - npm audit for dependency vulnerabilities
   - CodeQL analysis

4. **Build**
   - Docker image building
   - Push to Azure Container Registry (ACR)

5. **Deployment**
   - Staging environment deployment
   - Production environment deployment (after staging approval)

### Required Secrets

The following secrets need to be configured in GitHub:

- `ACR_LOGIN_SERVER`: Azure Container Registry login server
- `ACR_USERNAME`: Azure Container Registry username
- `ACR_PASSWORD`: Azure Container Registry password
- `AZURE_CREDENTIALS`: Azure service principal credentials
- `AKS_RESOURCE_GROUP`: Azure resource group name
- `AKS_CLUSTER_NAME`: AKS cluster name

### Development Workflow

1. Create a feature branch from `main`
2. Make your changes
3. Run tests locally:
   ```bash
   cd frontend
   npm install
   npm test
   ```
4. Create a pull request to `main`
5. Wait for all checks to pass
6. Get code review approval
7. Merge to `main`

### Deployment Environments

- **Staging**: https://staging.inspira-project.com
  - Automatic deployment on merge to `main`
  - Used for testing before production

- **Production**: https://inspira-project.com
  - Manual approval required
  - Deployed after successful staging deployment

### Monitoring

- Application metrics: Azure Monitor
- Log analytics: Azure Log Analytics
- Container insights: AKS monitoring

### Troubleshooting

If the pipeline fails:

1. Check the GitHub Actions logs
2. Verify all required secrets are configured
3. Ensure test coverage meets minimum requirements
4. Check for security vulnerabilities in dependencies
5. Verify Kubernetes manifests are valid

For deployment issues:

1. Check AKS cluster health
2. Verify ACR connectivity
3. Check pod logs in the relevant namespace
4. Verify environment configurations

## Monitoring

The platform is monitored using Prometheus and Grafana. For more information, see:

- [Monitoring Solution](docs/MONITORING-SOLUTION.md)

## Load Testing

The platform is load tested using JMeter. For more information, see:

- [Autoscaling and Load Testing](docs/AUTOSCALING-AND-LOAD-TESTING.md)

## Scripts

The repository contains various scripts for deployment, testing, and infrastructure management:

- **CI/CD Scripts**: `scripts/ci-cd/`
- **Deployment Scripts**: `scripts/deployment/`
- **Infrastructure Scripts**: `scripts/infrastructure/`
- **Testing Scripts**: `scripts/testing/`

## Troubleshooting

### URGENT: Frontend White Screen Fix for Azure (IP starting with 4.x.x.x)

If you're experiencing a white screen when accessing the frontend through the Azure IP (starting with 4.x.x.x), use:

```bash
./scripts/deployment/fix-azure-frontend-urgent.sh
```

This script creates a completely new frontend deployment with a simple static HTML page. For more details, see [Urgent Fixes](docs/deployment/URGENT-FIXES.md).

### URGENT: Frontend White Screen Fix for Docker Compose

If you're experiencing white screens when running with Docker Compose, especially after login or on profile pages, use:

```bash
./scripts/deployment/fix-docker-compose-urgent.sh
```

This script creates a completely new frontend with a simple static HTML page. For more details, see [Urgent Fixes](docs/deployment/URGENT-FIXES.md).

### Frontend White Screen Issue in Azure

For less urgent Azure frontend issues, you can use:

```bash
./scripts/deployment/fix-frontend-azure.sh
```

This script will create the necessary configuration and redeploy the frontend properly. For more information, see the [Azure Deployment Fixes](docs/deployment/AZURE-DEPLOYMENT-FIXES.md).

### Frontend White Screen Issue in Docker Compose

For less urgent Docker Compose frontend issues, you can use:

```bash
./scripts/deployment/fix-frontend-local.sh
```

This script will rebuild the frontend container with the correct configuration. For more details, see the [Docker Compose Fixes](docs/deployment/DOCKER-COMPOSE-FIXES.md).

### User Service Database Connection Issue

If the user service is having trouble connecting to the database when running with docker-compose, we've updated the configuration to fix this issue. Simply run:

```bash
docker-compose down
docker-compose up -d
```

For more details on the fix, see the [Azure Deployment Fixes](docs/deployment/AZURE-DEPLOYMENT-FIXES.md).

### Monitoring Access Issues

If you're having trouble accessing Prometheus or Grafana, the access scripts now include automatic port selection if the default ports are already in use:

```bash
./scripts/infrastructure/access-prometheus.sh
./scripts/infrastructure/access-grafana.sh
```

## License

This project is licensed under the terms of the license included in the [LICENSE](LICENSE) file.

## Monitoring and Autoscaling

The platform includes monitoring and autoscaling capabilities:

- **Prometheus**: Collects metrics from all services
- **Grafana**: Visualizes metrics in dashboards
- **Horizontal Pod Autoscaler**: Automatically scales services based on load

For more details, see [Monitoring Solution](./docs/MONITORING-SOLUTION.md) and [Autoscaling and Load Testing](./docs/AUTOSCALING-AND-LOAD-TESTING.md).

## Distributed Systems

The platform uses distributed databases and storage systems:

- PostgreSQL database sharding
- MinIO distributed object storage
- Azure Blob Storage with geo-replication

For more details, see [Distributed Systems Summary](./docs/DISTRIBUTED-SYSTEMS-SUMMARY.md).

## Cloud Services Integration

The platform integrates with various cloud services:

- Azure Kubernetes Service (AKS)
- Azure Container Registry (ACR)
- Azure Blob Storage
- Azure Monitor

For more details, see [Cloud Services Integration](./docs/CLOUD-SERVICES-INTEGRATION.md).
