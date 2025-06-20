# Inspira Platform Documentation

This directory contains all documentation for the Inspira Platform.

## Documentation Structure

- **API Documentation** (`/api/`)
  - [API Specifications](api/API's.txt) - API endpoints and specifications

- **Architecture Documentation** (`/architecture/`)
  - [External IP Configuration](architecture/EXTERNAL-IP-CONFIGURATION.md) - How to configure external IPs
  - [External Services](architecture/EXTERNAL-SERVICES.md) - Documentation for external services
  - [Frontend Solution](architecture/FRONTEND-SOLUTION.md) - Frontend architecture and design

- **Deployment Documentation** (`/deployment/`)
  - [Deployment Guide](deployment/DEPLOYMENT-GUIDE.md) - General deployment instructions
  - [Azure Deployment](deployment/AZURE-DEPLOYMENT.md) - Azure-specific deployment instructions
  - [Production Deployment](deployment/DEPLOYMENT-PRODUCTION.md) - Production deployment guidelines

## Additional Resources

For more information about the project, refer to the [main README](../README.md) file. 

# Inspira Platform

Welcome to the Inspira Platform repository. This repository contains the source code for the Inspira microservices platform.

## Documentation

- [Deployment Guide](deployment/DEPLOYMENT-GUIDE.md)
- [Production Deployment](deployment/DEPLOYMENT-PRODUCTION.md)
- [Azure Deployment](deployment/AZURE-DEPLOYMENT.md)
- [External Services](architecture/EXTERNAL-SERVICES.md)
- [Frontend Solution](architecture/FRONTEND-SOLUTION.md)
- [External IP Configuration](architecture/EXTERNAL-IP-CONFIGURATION.md)
- [Autoscaling and Load Testing](AUTOSCALING-AND-LOAD-TESTING.md)
- [Monitoring Solution](MONITORING-SOLUTION.md)

## Architecture

Inspira is built on a microservices architecture with the following components:

- **API Gateway**: Routes requests to appropriate services
- **User Service**: Manages user profiles and authentication
- **Content Service**: Handles content storage and retrieval
- **Media Service**: Processes media files (images, videos)
- **Frontend**: React-based web application

## Kubernetes Features

### Autoscaling

The platform uses Kubernetes Horizontal Pod Autoscalers (HPAs) to automatically scale services based on CPU and memory utilization. Each service is configured to scale between 1 and 5 pods when CPU or memory utilization exceeds 80%.

The autoscaling configuration can be found in `k8s/base/horizontal-pod-autoscalers.yaml`.

### Load Testing

To verify that autoscaling works correctly, we provide load testing scripts in the `scripts/testing` directory:

- `load-test.sh`: Performs load testing using Apache JMeter
- `verify-autoscaling.sh`: Monitors and verifies Kubernetes autoscaling
- `run-load-test.sh`: Combined script to run load tests and verify autoscaling

To run a load test and verify autoscaling:

```bash
./scripts/testing/run-load-test.sh --duration=300 --threads=100 --host=your-ingress-ip
```

This will generate an HTML report showing whether the services scaled correctly under load.

## Getting Started

See the [Deployment Guide](deployment/DEPLOYMENT-GUIDE.md) for instructions on setting up the platform. 