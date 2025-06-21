# Inspira Platform

Inspira is a cloud-native microservices platform built with modern technologies and deployed on Azure Kubernetes Service (AKS).

## Architecture

The platform consists of the following microservices:

- **Frontend**: A web interface built with React
- **API Gateway**: Routes requests to appropriate microservices
- **User Service**: Manages user accounts and authentication
- **Content Service**: Handles content storage and retrieval
- **Media Service**: Processes and stores media files

## CI/CD Pipeline

The platform uses a fully automated CI/CD pipeline that includes:

1. **Security Scanning**: Uses Trivy to scan for vulnerabilities
2. **Build**: Builds Docker images for all microservices
3. **Test**: Runs automated tests for all microservices
4. **Load Testing**: Performs load testing to ensure performance
5. **Deploy to Staging**: Deploys to the staging environment
6. **Deploy to Production**: Deploys to the production environment

For more details, see [CI/CD Pipeline Documentation](./docs/CI-CD-PIPELINE.md).

## Deployment

The platform is deployed on Azure Kubernetes Service (AKS) using Kubernetes manifests. For deployment instructions, see:

- [Deployment Guide](./docs/deployment/DEPLOYMENT-GUIDE.md)
- [Azure Deployment](./docs/deployment/AZURE-DEPLOYMENT.md)
- [Production Deployment](./docs/deployment/DEPLOYMENT-PRODUCTION.md)

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
