# Monitoring Solution: Prometheus and Grafana

## Overview

This document outlines the monitoring solution implemented for the Inspira platform using Prometheus and Grafana. These tools provide comprehensive monitoring capabilities that complement our autoscaling and load testing implementation.

## Monitoring Architecture

The monitoring stack consists of:

1. **Prometheus** - Time-series database and monitoring system
2. **Grafana** - Visualization and dashboarding platform
3. **Service Monitors** - Kubernetes custom resources that define scraping targets
4. **Node Exporters** - Collect system metrics from nodes
5. **cAdvisor** - Container resource usage metrics

## Prometheus

Prometheus is the core of our monitoring solution, responsible for:

- **Data Collection**: Scrapes metrics from services, pods, and nodes
- **Storage**: Time-series database for metrics
- **Alerting**: Configurable alerts based on metric thresholds
- **Query Language**: PromQL for flexible data querying

### Configuration

Prometheus is configured to monitor:

- Kubernetes API server
- Nodes (CPU, memory, disk usage)
- Pods (container metrics)
- Service-specific metrics (via annotations and ServiceMonitors)

The configuration can be found in:
```
k8s/base/service-monitors.yaml
```

## Grafana

Grafana provides visualization and dashboarding for metrics collected by Prometheus:

- **Dashboards**: Pre-configured dashboards for Kubernetes, nodes, and services
- **Visualization**: Rich graphing capabilities for time-series data
- **Alerting**: Visual alerts based on thresholds
- **Annotations**: Mark events like deployments on graphs

### Dashboards

Key dashboards implemented:

1. **Kubernetes Cluster Overview**: Overall cluster health and resource usage
2. **Node Performance**: Detailed metrics for each node
3. **Pod Resources**: CPU, memory, and network usage per pod
4. **Service Performance**: Request rate, latency, and error rates
5. **Autoscaling Metrics**: HPA metrics and scaling events

## Integration with Autoscaling

Our monitoring solution is tightly integrated with the autoscaling implementation:

1. **Metrics Collection**: Prometheus collects the same CPU and memory metrics used by HPAs
2. **Visualization**: Grafana dashboards show resource usage alongside scaling events
3. **Historical Analysis**: Ability to review past scaling events and their triggers
4. **Threshold Visualization**: Dashboards show the 80% thresholds that trigger scaling

## Setting Up Monitoring

To set up Prometheus and Grafana for monitoring the frontend and user service, use one of the provided scripts:

```bash
# Option 1: Standard setup with separate Prometheus and Grafana installations
./scripts/infrastructure/setup-monitoring.sh

# Option 2: Simplified setup using kube-prometheus-stack (recommended)
./scripts/infrastructure/setup-monitoring-simple.sh
```

This script:
1. Creates a monitoring namespace
2. Installs Prometheus with configuration for scraping frontend and user service
3. Installs Grafana with pre-configured dashboards
4. Sets up appropriate service monitors
5. Adds necessary annotations to deployments
6. Creates access scripts for both tools

### Accessing Monitoring

Once set up, the monitoring stack can be accessed using:

```bash
# Access Grafana
./scripts/infrastructure/access-grafana.sh

# Access Prometheus
./scripts/infrastructure/access-prometheus.sh

# Default credentials for Grafana
# Username: admin
# Password: Retrieved from Kubernetes secret
```

## Container-Level Monitoring

Each container is monitored individually with metrics including:

- **CPU Usage**: Actual CPU consumption vs. requests/limits
- **Memory Usage**: Current memory consumption and trends
- **Network I/O**: Network traffic in/out
- **Disk I/O**: Storage read/write operations
- **Request Handling**: Request rates, latencies, and error rates

## Load Testing Integration

The monitoring solution complements load testing by:

1. **Real-time Visibility**: Watch system behavior during tests
2. **Performance Correlation**: Correlate load with resource usage
3. **Bottleneck Identification**: Identify resource constraints
4. **Scaling Validation**: Confirm autoscaling works as expected

## Conclusion

The combination of Prometheus and Grafana provides comprehensive monitoring capabilities that satisfy the requirements for:

1. **Container-level monitoring**: Detailed metrics for each container
2. **Resource usage tracking**: CPU, memory, network, and disk monitoring
3. **Performance visualization**: Graphical representation of system behavior
4. **Autoscaling verification**: Confirmation that scaling policies work correctly
5. **Historical analysis**: Review of past performance and scaling events

This monitoring solution is essential for both development and production environments, providing the visibility needed to ensure the platform performs optimally under various load conditions. 