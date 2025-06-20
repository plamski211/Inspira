# Inspira Platform

Inspira is a microservices-based platform for content creation and sharing.

## Architecture

The platform consists of the following components:

### Backend Services

1. **API Gateway** - Routes requests to appropriate services
   - Port: 8000
   - Routes all `/api/*` requests to the appropriate microservice

2. **User Service** - Handles user authentication and profiles
   - Port: 8080
   - Endpoints: `/api/users/*`
   - Database: PostgreSQL (users)
   - Authentication: Auth0

3. **Content Service** - Manages content metadata and file uploads
   - Port: 8081
   - Endpoints: `/api/content/*`
   - Database: PostgreSQL (content)
   - Storage: MinIO (content-files bucket)

4. **Media Service** - Processes and optimizes uploaded content
   - Port: 8082
   - Endpoints: `/api/media/*`
   - Database: PostgreSQL (media)
   - Storage: MinIO (media-files bucket)

### Frontend

- React application
- Development port: 5173
- Production port: 4173

## Project Structure

```
inspira_github/
├── api-gateway/         # Spring Boot API Gateway service
├── content-service/     # Spring Boot Content service
├── media-service/       # Spring Boot Media Processing service
├── user-service/        # Spring Boot User service
├── frontend/            # React frontend application
├── config/              # Configuration files
│   ├── frontend/        # Frontend configuration
│   └── nginx/           # Nginx configuration
├── docs/                # Documentation
│   ├── api/             # API documentation
│   ├── architecture/    # Architecture documentation
│   └── deployment/      # Deployment guides
├── k8s/                 # Kubernetes manifests
│   ├── base/            # Base Kubernetes configurations
│   └── overlays/        # Environment-specific overlays
│       ├── dev/         # Development environment
│       ├── prod/        # Production environment
│       └── azure/       # Azure-specific configurations
├── scripts/             # Utility scripts
│   ├── ci-cd/           # CI/CD scripts
│   ├── deployment/      # Deployment scripts
│   ├── infrastructure/  # Infrastructure management scripts
│   └── testing/         # Testing scripts
└── docker-compose.yml   # Local development setup
```

## Getting Started

### Prerequisites

- Docker and Docker Compose
- Node.js 16+
- Java 17+

### Running the Platform

1. Start the backend services:

```bash
docker-compose up -d
```

2. Start the frontend in development mode:

```bash
cd frontend
npm install
npm run dev
```

3. Access the application at http://localhost:5173

## Testing

### Service Testing

You can test the services using the provided script:

```bash
./scripts/testing/test-services.sh
```

### Load Testing and Autoscaling

The platform includes comprehensive load testing and autoscaling capabilities:

```bash
# Run load test with autoscaling verification
./scripts/testing/run-load-test.sh --duration=300 --threads=100

# Generate CPU load directly in pods
./scripts/testing/simple-cpu-load.sh --service=content-service
```

For detailed information, see [Autoscaling and Load Testing Documentation](docs/AUTOSCALING-AND-LOAD-TESTING.md)

### Monitoring with Prometheus and Grafana

The platform uses Prometheus and Grafana for comprehensive monitoring:

- **Prometheus**: Collects and stores metrics from all services and infrastructure
- **Grafana**: Provides visualization dashboards for monitoring system performance

```bash
# Access Grafana dashboards
./scripts/infrastructure/access-grafana.sh
```

Monitoring capabilities include:
- Container-level resource usage (CPU, memory, network, disk)
- Service performance metrics (request rate, latency, errors)
- Autoscaling events and triggers
- Historical performance analysis

For detailed information, see [Monitoring Solution Documentation](docs/MONITORING-SOLUTION.md)

## Deployment

For deployment instructions, see the documentation in the `docs/deployment/` directory:

- [General Deployment Guide](docs/deployment/DEPLOYMENT-GUIDE.md)
- [Azure Deployment Guide](docs/deployment/AZURE-DEPLOYMENT.md)
- [Production Deployment Guide](docs/deployment/DEPLOYMENT-PRODUCTION.md)

## Service Communication

- **User Service** → Auth0: Authentication
- **Content Service** → Media Service: Content processing
- **Media Service** → Content Service: Processing callbacks
- **Frontend** → API Gateway → All Services

## File Upload Flow

1. User uploads file via Frontend
2. API Gateway routes request to Content Service
3. Content Service stores file in MinIO and metadata in PostgreSQL
4. Content Service requests processing from Media Service
5. Media Service processes file and stores optimized version
6. Media Service notifies Content Service when processing is complete
7. User can access both original and processed versions

## Documentation

- [Deployment Guide](docs/deployment/DEPLOYMENT-GUIDE.md)
- [Azure Deployment](docs/deployment/AZURE-DEPLOYMENT.md)
- [Production Deployment](docs/deployment/DEPLOYMENT-PRODUCTION.md)
- [External Services](docs/architecture/EXTERNAL-SERVICES.md)
- [Frontend Solution](docs/architecture/FRONTEND-SOLUTION.md)
- [External IP Configuration](docs/architecture/EXTERNAL-IP-CONFIGURATION.md)
- [Autoscaling and Load Testing](docs/AUTOSCALING-AND-LOAD-TESTING.md)
- [Monitoring Solution](docs/MONITORING-SOLUTION.md)
- [CI/CD Pipeline](docs/CI-CD-PIPELINE.md)

## Monitoring and Autoscaling

The Inspira platform includes comprehensive monitoring and autoscaling capabilities:

### Monitoring

The monitoring stack is based on Prometheus and Grafana:

```bash
# Set up monitoring
./scripts/infrastructure/setup-monitoring-simple.sh

# Access Grafana
./scripts/infrastructure/access-grafana.sh

# Access Prometheus
./scripts/infrastructure/access-prometheus.sh
```

For more details, see the [Monitoring Solution](docs/MONITORING-SOLUTION.md) documentation.

### Autoscaling

Kubernetes Horizontal Pod Autoscalers (HPAs) are configured to automatically scale services based on CPU and memory usage:

```bash
# View current HPA status
kubectl get hpa -n microservices

# Test autoscaling
./scripts/testing/trigger-autoscale.sh
```

For more details, see the [Autoscaling and Load Testing](docs/AUTOSCALING-AND-LOAD-TESTING.md) documentation.

## CI/CD Pipeline

The project includes a complete CI/CD pipeline that automates:

- Security scanning
- Building and pushing Docker images
- Running tests
- Deploying to staging and production
- Setting up monitoring and autoscaling

The pipeline is defined in `.github/workflows/azure-deploy-prod.yml`.

For more details, see the [CI/CD Pipeline](docs/CI-CD-PIPELINE.md) documentation.
