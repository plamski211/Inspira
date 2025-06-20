#!/bin/bash

# Simple script to set up Prometheus and Grafana for monitoring frontend and user service
# This script uses the kube-prometheus-stack chart which includes Prometheus, Grafana, and AlertManager

set -e

# Default values
NAMESPACE="monitoring"
CHART_VERSION="56.6.1"  # Latest stable version of kube-prometheus-stack

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --namespace=*)
      NAMESPACE="${1#*=}"
      shift
      ;;
    --version=*)
      CHART_VERSION="${1#*=}"
      shift
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  --namespace=NAMESPACE    Kubernetes namespace for monitoring tools (default: monitoring)"
      echo "  --version=VERSION        Chart version for kube-prometheus-stack (default: 56.6.1)"
      echo "  --help                   Display this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo "========================================="
echo "Setting up Prometheus and Grafana using kube-prometheus-stack"
echo "========================================="
echo "Namespace: $NAMESPACE"
echo "Chart version: $CHART_VERSION"
echo "========================================="

# Create namespace if it doesn't exist
echo "Creating namespace $NAMESPACE (if it doesn't exist)..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Add Helm repositories
echo "Adding Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create ServiceMonitor for frontend and user service
echo "Creating ServiceMonitor for frontend and user service..."
cat > service-monitor.yaml << EOF
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: frontend-user-service-monitor
  namespace: $NAMESPACE
  labels:
    release: prometheus
spec:
  selector:
    matchLabels:
      app: frontend
  namespaceSelector:
    matchNames:
      - microservices
  endpoints:
  - port: http
    path: /metrics
    interval: 15s
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: user-service-monitor
  namespace: $NAMESPACE
  labels:
    release: prometheus
spec:
  selector:
    matchLabels:
      app: user-service
  namespaceSelector:
    matchNames:
      - microservices
  endpoints:
  - port: http
    path: /metrics
    interval: 15s
EOF

# Create values file for Helm chart
echo "Creating values file for Helm chart..."
cat > prometheus-values.yaml << EOF
prometheus:
  prometheusSpec:
    serviceMonitorSelectorNilUsesHelmValues: false
    serviceMonitorSelector: {}
    serviceMonitorNamespaceSelector: {}
    podMonitorSelectorNilUsesHelmValues: false
    podMonitorSelector: {}
    podMonitorNamespaceSelector: {}

grafana:
  adminPassword: admin
  dashboardProviders:
    dashboardproviders.yaml:
      apiVersion: 1
      providers:
      - name: 'default'
        orgId: 1
        folder: ''
        type: file
        disableDeletion: false
        editable: true
        options:
          path: /var/lib/grafana/dashboards/default
  dashboards:
    default:
      frontend-user-dashboard:
        json: |
          {
            "annotations": {
              "list": []
            },
            "editable": true,
            "fiscalYearStartMonth": 0,
            "graphTooltip": 0,
            "id": 1,
            "links": [],
            "liveNow": false,
            "panels": [
              {
                "datasource": {
                  "type": "prometheus",
                  "uid": "prometheus"
                },
                "fieldConfig": {
                  "defaults": {
                    "color": {
                      "mode": "palette-classic"
                    },
                    "custom": {
                      "axisCenteredZero": false,
                      "axisColorMode": "text",
                      "axisLabel": "",
                      "axisPlacement": "auto",
                      "barAlignment": 0,
                      "drawStyle": "line",
                      "fillOpacity": 10,
                      "gradientMode": "none",
                      "hideFrom": {
                        "legend": false,
                        "tooltip": false,
                        "viz": false
                      },
                      "lineInterpolation": "linear",
                      "lineWidth": 1,
                      "pointSize": 5,
                      "scaleDistribution": {
                        "type": "linear"
                      },
                      "showPoints": "never",
                      "spanNulls": false,
                      "stacking": {
                        "group": "A",
                        "mode": "none"
                      },
                      "thresholdsStyle": {
                        "mode": "off"
                      }
                    },
                    "mappings": [],
                    "thresholds": {
                      "mode": "absolute",
                      "steps": [
                        {
                          "color": "green",
                          "value": null
                        },
                        {
                          "color": "red",
                          "value": 80
                        }
                      ]
                    },
                    "unit": "percentunit"
                  },
                  "overrides": []
                },
                "gridPos": {
                  "h": 8,
                  "w": 12,
                  "x": 0,
                  "y": 0
                },
                "id": 1,
                "options": {
                  "legend": {
                    "calcs": [],
                    "displayMode": "list",
                    "placement": "bottom",
                    "showLegend": true
                  },
                  "tooltip": {
                    "mode": "multi",
                    "sort": "none"
                  }
                },
                "targets": [
                  {
                    "datasource": {
                      "type": "prometheus",
                      "uid": "prometheus"
                    },
                    "expr": "sum(rate(container_cpu_usage_seconds_total{namespace=\\\"microservices\\\", pod=~\\\"frontend-.*|user-service-.*\\\"}[5m])) by (pod) / sum(kube_pod_container_resource_requests{namespace=\\\"microservices\\\", pod=~\\\"frontend-.*|user-service-.*\\\", resource=\\\"cpu\\\"}) by (pod)",
                    "interval": "",
                    "legendFormat": "{{pod}} - CPU Usage",
                    "refId": "A"
                  }
                ],
                "title": "CPU Usage (% of Request)",
                "type": "timeseries"
              },
              {
                "datasource": {
                  "type": "prometheus",
                  "uid": "prometheus"
                },
                "fieldConfig": {
                  "defaults": {
                    "color": {
                      "mode": "palette-classic"
                    },
                    "custom": {
                      "axisCenteredZero": false,
                      "axisColorMode": "text",
                      "axisLabel": "",
                      "axisPlacement": "auto",
                      "barAlignment": 0,
                      "drawStyle": "line",
                      "fillOpacity": 10,
                      "gradientMode": "none",
                      "hideFrom": {
                        "legend": false,
                        "tooltip": false,
                        "viz": false
                      },
                      "lineInterpolation": "linear",
                      "lineWidth": 1,
                      "pointSize": 5,
                      "scaleDistribution": {
                        "type": "linear"
                      },
                      "showPoints": "never",
                      "spanNulls": false,
                      "stacking": {
                        "group": "A",
                        "mode": "none"
                      },
                      "thresholdsStyle": {
                        "mode": "off"
                      }
                    },
                    "mappings": [],
                    "thresholds": {
                      "mode": "absolute",
                      "steps": [
                        {
                          "color": "green",
                          "value": null
                        },
                        {
                          "color": "red",
                          "value": 80
                        }
                      ]
                    },
                    "unit": "percentunit"
                  },
                  "overrides": []
                },
                "gridPos": {
                  "h": 8,
                  "w": 12,
                  "x": 12,
                  "y": 0
                },
                "id": 2,
                "options": {
                  "legend": {
                    "calcs": [],
                    "displayMode": "list",
                    "placement": "bottom",
                    "showLegend": true
                  },
                  "tooltip": {
                    "mode": "multi",
                    "sort": "none"
                  }
                },
                "targets": [
                  {
                    "datasource": {
                      "type": "prometheus",
                      "uid": "prometheus"
                    },
                    "expr": "sum(container_memory_working_set_bytes{namespace=\\\"microservices\\\", pod=~\\\"frontend-.*|user-service-.*\\\"}) by (pod) / sum(kube_pod_container_resource_requests{namespace=\\\"microservices\\\", pod=~\\\"frontend-.*|user-service-.*\\\", resource=\\\"memory\\\"}) by (pod)",
                    "interval": "",
                    "legendFormat": "{{pod}} - Memory Usage",
                    "refId": "A"
                  }
                ],
                "title": "Memory Usage (% of Request)",
                "type": "timeseries"
              },
              {
                "datasource": {
                  "type": "prometheus",
                  "uid": "prometheus"
                },
                "fieldConfig": {
                  "defaults": {
                    "color": {
                      "mode": "thresholds"
                    },
                    "mappings": [],
                    "thresholds": {
                      "mode": "absolute",
                      "steps": [
                        {
                          "color": "green",
                          "value": null
                        },
                        {
                          "color": "yellow",
                          "value": 0.7
                        },
                        {
                          "color": "red",
                          "value": 0.85
                        }
                      ]
                    },
                    "unit": "percentunit"
                  },
                  "overrides": []
                },
                "gridPos": {
                  "h": 8,
                  "w": 12,
                  "x": 0,
                  "y": 8
                },
                "id": 3,
                "options": {
                  "orientation": "auto",
                  "reduceOptions": {
                    "calcs": [
                      "lastNotNull"
                    ],
                    "fields": "",
                    "values": false
                  },
                  "showThresholdLabels": false,
                  "showThresholdMarkers": true
                },
                "pluginVersion": "10.0.3",
                "targets": [
                  {
                    "datasource": {
                      "type": "prometheus",
                      "uid": "prometheus"
                    },
                    "expr": "sum(kube_hpa_status_current_metrics_value{namespace=\\\"microservices\\\", hpa=~\\\"frontend|user-service\\\"}) by (hpa) / sum(kube_hpa_spec_target_metric{namespace=\\\"microservices\\\", hpa=~\\\"frontend|user-service\\\"}) by (hpa)",
                    "interval": "",
                    "legendFormat": "{{hpa}} - Current/Target",
                    "refId": "A"
                  }
                ],
                "title": "HPA Current/Target Ratio",
                "type": "gauge"
              },
              {
                "datasource": {
                  "type": "prometheus",
                  "uid": "prometheus"
                },
                "fieldConfig": {
                  "defaults": {
                    "color": {
                      "mode": "palette-classic"
                    },
                    "custom": {
                      "axisCenteredZero": false,
                      "axisColorMode": "text",
                      "axisLabel": "",
                      "axisPlacement": "auto",
                      "barAlignment": 0,
                      "drawStyle": "line",
                      "fillOpacity": 10,
                      "gradientMode": "none",
                      "hideFrom": {
                        "legend": false,
                        "tooltip": false,
                        "viz": false
                      },
                      "lineInterpolation": "linear",
                      "lineWidth": 1,
                      "pointSize": 5,
                      "scaleDistribution": {
                        "type": "linear"
                      },
                      "showPoints": "never",
                      "spanNulls": false,
                      "stacking": {
                        "group": "A",
                        "mode": "none"
                      },
                      "thresholdsStyle": {
                        "mode": "off"
                      }
                    },
                    "mappings": [],
                    "thresholds": {
                      "mode": "absolute",
                      "steps": [
                        {
                          "color": "green",
                          "value": null
                        }
                      ]
                    }
                  },
                  "overrides": []
                },
                "gridPos": {
                  "h": 8,
                  "w": 12,
                  "x": 12,
                  "y": 8
                },
                "id": 4,
                "options": {
                  "legend": {
                    "calcs": [],
                    "displayMode": "list",
                    "placement": "bottom",
                    "showLegend": true
                  },
                  "tooltip": {
                    "mode": "multi",
                    "sort": "none"
                  }
                },
                "targets": [
                  {
                    "datasource": {
                      "type": "prometheus",
                      "uid": "prometheus"
                    },
                    "expr": "sum(kube_hpa_status_replicas{namespace=\\\"microservices\\\", hpa=~\\\"frontend|user-service\\\"}) by (hpa)",
                    "interval": "",
                    "legendFormat": "{{hpa}} - Current Replicas",
                    "refId": "A"
                  },
                  {
                    "datasource": {
                      "type": "prometheus",
                      "uid": "prometheus"
                    },
                    "expr": "sum(kube_hpa_spec_min_replicas{namespace=\\\"microservices\\\", hpa=~\\\"frontend|user-service\\\"}) by (hpa)",
                    "interval": "",
                    "legendFormat": "{{hpa}} - Min Replicas",
                    "refId": "B"
                  },
                  {
                    "datasource": {
                      "type": "prometheus",
                      "uid": "prometheus"
                    },
                    "expr": "sum(kube_hpa_spec_max_replicas{namespace=\\\"microservices\\\", hpa=~\\\"frontend|user-service\\\"}) by (hpa)",
                    "interval": "",
                    "legendFormat": "{{hpa}} - Max Replicas",
                    "refId": "C"
                  }
                ],
                "title": "HPA Replicas",
                "type": "timeseries"
              }
            ],
            "refresh": "10s",
            "schemaVersion": 38,
            "style": "dark",
            "tags": [],
            "templating": {
              "list": []
            },
            "time": {
              "from": "now-1h",
              "to": "now"
            },
            "timepicker": {},
            "timezone": "",
            "title": "Frontend and User Service Overview",
            "uid": "frontend-user-service-overview",
            "version": 1,
            "weekStart": ""
          }
EOF

# Install kube-prometheus-stack using Helm
echo "Installing kube-prometheus-stack..."
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace $NAMESPACE \
  --version $CHART_VERSION \
  --values prometheus-values.yaml \
  --timeout 10m

# Wait for deployments to be ready
echo "Waiting for Prometheus to be ready..."
kubectl rollout status deployment/prometheus-kube-prometheus-operator -n $NAMESPACE --timeout=300s || true

echo "Waiting for Grafana to be ready..."
kubectl rollout status deployment/prometheus-grafana -n $NAMESPACE --timeout=300s || true

# Apply ServiceMonitor resources
kubectl apply -f service-monitor.yaml

# Create access scripts
echo "Creating access scripts..."

# Create Grafana access script
cat > access-grafana.sh << EOF
#!/bin/bash

# Get the Grafana admin password
GRAFANA_PASSWORD=\$(kubectl get secret --namespace $NAMESPACE prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode)
echo "Grafana admin password: \$GRAFANA_PASSWORD"

# Port forward to access Grafana
echo "Starting port forwarding to Grafana on port 3000..."
echo "Access Grafana at: http://localhost:3000"
echo "Username: admin"
echo "Password: \$GRAFANA_PASSWORD"
echo "Press Ctrl+C to stop port forwarding"
kubectl port-forward --namespace $NAMESPACE svc/prometheus-grafana 3000:80
EOF

chmod +x access-grafana.sh
mv access-grafana.sh scripts/infrastructure/

# Create Prometheus access script
cat > access-prometheus.sh << EOF
#!/bin/bash

# Port forward to access Prometheus
echo "Starting port forwarding to Prometheus on port 9090..."
echo "Access Prometheus at: http://localhost:9090"
echo "Press Ctrl+C to stop port forwarding"
kubectl port-forward --namespace $NAMESPACE svc/prometheus-kube-prometheus-prometheus 9090:9090
EOF

chmod +x access-prometheus.sh
mv access-prometheus.sh scripts/infrastructure/

# Clean up temporary files
rm -f prometheus-values.yaml service-monitor.yaml

echo "========================================="
echo "Setup Complete!"
echo "========================================="
echo "To access Grafana:"
echo "  ./scripts/infrastructure/access-grafana.sh"
echo ""
echo "To access Prometheus:"
echo "  ./scripts/infrastructure/access-prometheus.sh"
echo ""
echo "Default Grafana credentials:"
echo "  Username: admin"
echo "  Password: admin (or retrieved by the access script)"
echo "========================================="

# Add annotations to frontend and user service deployments for Prometheus scraping
echo "Adding Prometheus annotations to frontend and user-service deployments..."

# Create patch files
cat > frontend-prometheus-patch.yaml << EOF
spec:
  template:
    metadata:
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/path: "/metrics"
        prometheus.io/port: "80"
EOF

cat > user-service-prometheus-patch.yaml << EOF
spec:
  template:
    metadata:
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/path: "/metrics"
        prometheus.io/port: "80"
EOF

# Apply patches
kubectl patch deployment frontend -n microservices --patch "$(cat frontend-prometheus-patch.yaml)"
kubectl patch deployment user-service -n microservices --patch "$(cat user-service-prometheus-patch.yaml)"

# Clean up patch files
rm -f frontend-prometheus-patch.yaml user-service-prometheus-patch.yaml

echo "Annotations added to deployments."
echo "========================================="
echo "Restarting frontend and user-service pods to apply annotations..."

# Restart deployments to apply annotations
kubectl rollout restart deployment/frontend -n microservices
kubectl rollout restart deployment/user-service -n microservices

echo "Pods restarted. Setup is now complete!" 