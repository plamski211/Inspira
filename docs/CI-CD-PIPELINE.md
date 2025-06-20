# CI/CD Pipeline with Monitoring Integration

## Overview

This document outlines the complete CI/CD pipeline implemented for the Inspira platform, including automated testing, security scanning, deployment, and monitoring integration. The pipeline ensures that all code changes are properly tested, scanned for vulnerabilities, deployed, and monitored in both staging and production environments.

## Pipeline Architecture

The CI/CD pipeline consists of the following stages:

1. **Security Scanning**: Code is scanned for vulnerabilities using Trivy
2. **Build**: Docker images are built and pushed to Docker Hub
3. **Testing**: Unit tests are run for all services
4. **Load Testing**: Performance is verified using JMeter
5. **Staging Deployment**: Changes are deployed to the staging environment
6. **Production Deployment**: After approval, changes are deployed to production

## Security Scanning

Before building any images, the code is scanned for vulnerabilities:

- Trivy scanner checks for security issues in the codebase
- Results are uploaded to GitHub Security tab
- Critical vulnerabilities block the pipeline

## Build Process

Docker images are built and pushed to Docker Hub:

- Frontend
- API Gateway
- User Service
- Content Service
- Media Service

Each image is tagged with both the commit SHA and 'latest' tag.

## Automated Testing

Multiple testing types are integrated into the pipeline:

- **Unit Tests**: Run for each service
- **Integration Tests**: Run against the staging environment
- **Load Tests**: Verify performance under load using JMeter
- **Security Tests**: Scan Docker images for vulnerabilities

Test results are stored as artifacts for later review.

## Deployment Process

The deployment process follows these steps:

1. **Staging Deployment**:
   - Automatic deployment on push to main branch
   - Updates Kubernetes manifests with new image tags
   - Applies configurations for all services
   - Verifies successful deployment
   - Runs integration tests

2. **Production Deployment**:
   - Manual approval required
   - Updates Kubernetes manifests with new image tags
   - Applies configurations for all services
   - Verifies successful deployment
   - Performs health checks on all services

## Monitoring Integration

The pipeline integrates with monitoring tools:

1. **Service Monitors**: Applied during deployment to configure Prometheus scraping
2. **Horizontal Pod Autoscalers**: Applied to enable automatic scaling
3. **Verification**: Checks that Prometheus and Grafana are running
4. **Health Checks**: Verifies all service health endpoints

## Autoscaling Configuration

Horizontal Pod Autoscalers are configured for all services:

- Scale from 1 to 5 pods based on CPU and memory usage
- CPU threshold: 80%
- Memory threshold: 80%

## Accessing Monitoring

To access the monitoring tools:

```bash
# Access Prometheus
./scripts/infrastructure/access-prometheus.sh

# Access Grafana
./scripts/infrastructure/access-grafana.sh
```

## Pipeline Workflow

The complete workflow is defined in `.github/workflows/azure-deploy-prod.yml` and includes:

1. Security scan on code
2. Build and push Docker images
3. Run unit tests
4. Run load tests
5. Deploy to staging
6. Verify monitoring in staging
7. Manual approval for production
8. Deploy to production
9. Verify monitoring in production

## Continuous Monitoring

After deployment, the system is continuously monitored:

- **Prometheus**: Collects metrics from all services
- **Grafana**: Visualizes metrics in dashboards
- **Alerts**: Configured for critical conditions
- **Autoscaling**: Automatically adjusts resources based on load

## Conclusion

This CI/CD pipeline ensures that all changes to the Inspira platform are properly tested, secured, deployed, and monitored. The integration of security scanning, automated testing, and monitoring provides a comprehensive solution for maintaining a reliable and performant application. 