# Inspira Platform Scripts

This directory contains various scripts for deploying, testing, and managing the Inspira Platform.

## Script Categories

- **CI/CD Scripts** (`/ci-cd/`)
  - Scripts for continuous integration and deployment

- **Deployment Scripts** (`/deployment/`)
  - Scripts for deploying the platform to various environments

- **Infrastructure Scripts** (`/infrastructure/`)
  - Scripts for managing infrastructure components

- **Testing Scripts** (`/testing/`)
  - Scripts for testing the platform, including load testing and autoscaling verification

## Testing Scripts

The testing directory contains scripts for load testing and verifying autoscaling behavior:

### Load Testing Scripts

- **load-test.sh**: Main load testing script using Apache JMeter
  ```bash
  ./scripts/testing/load-test.sh --duration=300 --threads=50 --host=your-ingress-ip
  ```

- **run-load-test.sh**: Comprehensive script that runs load tests and monitors autoscaling
  ```bash
  ./scripts/testing/run-load-test.sh --duration=300 --threads=100 --host=your-ingress-ip
  ```

- **moderate-load-test.sh**: Balanced load test that won't overwhelm the system
  ```bash
  ./scripts/testing/moderate-load-test.sh --host=your-ingress-ip
  ```

- **heavy-load-test.sh**: Aggressive load test to trigger autoscaling quickly
  ```bash
  ./scripts/testing/heavy-load-test.sh --host=your-ingress-ip
  ```

### Autoscaling Verification Scripts

- **verify-autoscaling.sh**: Monitors Kubernetes HPAs during load tests
  ```bash
  ./scripts/testing/verify-autoscaling.sh --namespace=microservices --duration=300
  ```

- **simple-autoscale-test.sh**: Simple script to test autoscaling using curl
  ```bash
  ./scripts/testing/simple-autoscale-test.sh --service=content-service
  ```

- **pod-cpu-load.sh**: Generates CPU load directly inside pods
  ```bash
  ./scripts/testing/pod-cpu-load.sh --service=content-service --duration=300
  ```

- **simple-cpu-load.sh**: Simplified CPU load generator using the 'yes' command
  ```bash
  ./scripts/testing/simple-cpu-load.sh --service=content-service --duration=300
  ```

- **direct-cpu-load.sh**: Advanced CPU load generator with comprehensive monitoring
  ```bash
  ./scripts/testing/direct-cpu-load.sh --service=content-service --duration=300
  ```

### Service Verification Scripts

- **verify-services.sh**: Verifies that all services are running correctly
  ```bash
  ./scripts/testing/verify-services.sh
  ```

- **test-services.sh**: Tests all service endpoints
  ```bash
  ./scripts/testing/test-services.sh --host=your-ingress-ip
  ```

- **validate-deployment.sh**: Validates the entire deployment
  ```bash
  ./scripts/testing/validate-deployment.sh
  ```

## Usage Examples

### Complete Load Test with Autoscaling Verification

```bash
# Run a comprehensive load test and verify autoscaling
./scripts/testing/run-load-test.sh --duration=600 --threads=100 --host=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Generate HTML report from results
jmeter -g load-results/load-test-*.log -o load-test-report
```

### Direct CPU Load Generation for Autoscaling Testing

```bash
# Generate CPU load directly in pods to trigger autoscaling
./scripts/testing/direct-cpu-load.sh --service=content-service --duration=600

# Monitor autoscaling behavior
kubectl get hpa -n microservices -w
```

## Results

Load test and autoscaling results are stored in:
- `load-results/`: Standard load test results
- `autoscale-results/`: Autoscaling test results
- `load-test-results/`: Combined test results with logs 