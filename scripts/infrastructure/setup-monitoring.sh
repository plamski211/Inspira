#!/bin/bash

# Script to set up Prometheus and Grafana for monitoring frontend and user service
# This script installs Prometheus and Grafana in the Kubernetes cluster and configures
# them to monitor the frontend and user service.

set -e

# Default values
NAMESPACE="monitoring"
PROMETHEUS_VERSION="27.20.1"  # Latest available chart version
GRAFANA_VERSION="9.2.7"    # Latest available chart version

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --namespace=*)
      NAMESPACE="${1#*=}"
      shift
      ;;
    --prometheus-version=*)
      PROMETHEUS_VERSION="${1#*=}"
      shift
      ;;
    --grafana-version=*)
      GRAFANA_VERSION="${1#*=}"
      shift
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  --namespace=NAMESPACE           Kubernetes namespace for monitoring tools (default: monitoring)"
      echo "  --prometheus-version=VERSION    Prometheus version (default: 2.45.0)"
      echo "  --grafana-version=VERSION       Grafana version (default: 10.0.3)"
      echo "  --help                          Display this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo "========================================="
echo "Setting up Prometheus and Grafana"
echo "========================================="
echo "Namespace: $NAMESPACE"
echo "Prometheus version: $PROMETHEUS_VERSION"
echo "Grafana version: $GRAFANA_VERSION"
echo "========================================="

# Create namespace if it doesn't exist
echo "Creating namespace $NAMESPACE (if it doesn't exist)..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Add Helm repositories
echo "Adding Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Create a ConfigMap for Prometheus configuration
echo "Creating Prometheus configuration..."
cat > prometheus-config.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: $NAMESPACE
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
      evaluation_interval: 15s
    
    scrape_configs:
      - job_name: 'kubernetes-apiservers'
        kubernetes_sd_configs:
        - role: endpoints
        scheme: https
        tls_config:
          ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
        relabel_configs:
        - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
          action: keep
          regex: default;kubernetes;https
      
      - job_name: 'kubernetes-nodes'
        scheme: https
        tls_config:
          ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
        kubernetes_sd_configs:
        - role: node
        relabel_configs:
        - action: labelmap
          regex: __meta_kubernetes_node_label_(.+)
      
      - job_name: 'kubernetes-pods'
        kubernetes_sd_configs:
        - role: pod
        relabel_configs:
        - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
          action: keep
          regex: true
        - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
          action: replace
          target_label: __metrics_path__
          regex: (.+)
        - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
          action: replace
          regex: ([^:]+)(?::\\d+)?;(\\d+)
          replacement: \$1:\$2
          target_label: __address__
        - action: labelmap
          regex: __meta_kubernetes_pod_label_(.+)
        - source_labels: [__meta_kubernetes_namespace]
          action: replace
          target_label: kubernetes_namespace
        - source_labels: [__meta_kubernetes_pod_name]
          action: replace
          target_label: kubernetes_pod_name
      
      # Specific scrape config for frontend service
      - job_name: 'frontend'
        kubernetes_sd_configs:
        - role: endpoints
          namespaces:
            names:
            - microservices
        relabel_configs:
        - source_labels: [__meta_kubernetes_service_name]
          action: keep
          regex: frontend
        - source_labels: [__meta_kubernetes_pod_container_port_number]
          action: keep
          regex: 80
        - source_labels: [__meta_kubernetes_namespace]
          target_label: namespace
        - source_labels: [__meta_kubernetes_service_name]
          target_label: service
      
      # Specific scrape config for user service
      - job_name: 'user-service'
        kubernetes_sd_configs:
        - role: endpoints
          namespaces:
            names:
            - microservices
        relabel_configs:
        - source_labels: [__meta_kubernetes_service_name]
          action: keep
          regex: user-service
        - source_labels: [__meta_kubernetes_pod_container_port_number]
          action: keep
          regex: 80
        - source_labels: [__meta_kubernetes_namespace]
          target_label: namespace
        - source_labels: [__meta_kubernetes_service_name]
          target_label: service
EOF

kubectl apply -f prometheus-config.yaml

# Install Prometheus using Helm
echo "Installing Prometheus..."
helm upgrade --install prometheus prometheus-community/prometheus \
  --namespace $NAMESPACE \
  --set server.persistentVolume.enabled=true \
  --set server.persistentVolume.size=8Gi \
  --set server.configMapOverrideName=prometheus-config \
  --version $PROMETHEUS_VERSION

# Create a ConfigMap for Grafana dashboards
echo "Creating Grafana dashboards..."
cat > grafana-dashboards.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-dashboards
  namespace: $NAMESPACE
data:
  kubernetes-pod-overview.json: |
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
              "expr": "sum(rate(container_cpu_usage_seconds_total{namespace=~\"microservices\", pod=~\"frontend-.*|user-service-.*\"}[5m])) by (pod) / sum(kube_pod_container_resource_requests{namespace=~\"microservices\", pod=~\"frontend-.*|user-service-.*\", resource=\"cpu\"}) by (pod)",
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
              "expr": "sum(container_memory_working_set_bytes{namespace=~\"microservices\", pod=~\"frontend-.*|user-service-.*\"}) by (pod) / sum(kube_pod_container_resource_requests{namespace=~\"microservices\", pod=~\"frontend-.*|user-service-.*\", resource=\"memory\"}) by (pod)",
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
              },
              "unit": "reqps"
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
              "expr": "sum(rate(http_requests_total{namespace=~\"microservices\", pod=~\"frontend-.*|user-service-.*\"}[5m])) by (pod)",
              "interval": "",
              "legendFormat": "{{pod}} - Request Rate",
              "refId": "A"
            }
          ],
          "title": "HTTP Request Rate",
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
                    "value": 0.05
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
              "expr": "sum(rate(http_requests_total{namespace=~\"microservices\", pod=~\"frontend-.*|user-service-.*\", status=~\"5.*\"}[5m])) by (pod) / sum(rate(http_requests_total{namespace=~\"microservices\", pod=~\"frontend-.*|user-service-.*\"}[5m])) by (pod)",
              "interval": "",
              "legendFormat": "{{pod}} - Error Rate",
              "refId": "A"
            }
          ],
          "title": "HTTP Error Rate",
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
            "y": 16
          },
          "id": 5,
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
              "expr": "sum(kube_hpa_status_current_metrics_value{namespace=~\"microservices\", hpa=~\"frontend|user-service\"}) by (hpa) / sum(kube_hpa_spec_target_metric{namespace=~\"microservices\", hpa=~\"frontend|user-service\"}) by (hpa)",
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
            "y": 16
          },
          "id": 6,
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
              "expr": "sum(kube_hpa_status_replicas{namespace=~\"microservices\", hpa=~\"frontend|user-service\"}) by (hpa)",
              "interval": "",
              "legendFormat": "{{hpa}} - Current Replicas",
              "refId": "A"
            },
            {
              "datasource": {
                "type": "prometheus",
                "uid": "prometheus"
              },
              "expr": "sum(kube_hpa_spec_min_replicas{namespace=~\"microservices\", hpa=~\"frontend|user-service\"}) by (hpa)",
              "interval": "",
              "legendFormat": "{{hpa}} - Min Replicas",
              "refId": "B"
            },
            {
              "datasource": {
                "type": "prometheus",
                "uid": "prometheus"
              },
              "expr": "sum(kube_hpa_spec_max_replicas{namespace=~\"microservices\", hpa=~\"frontend|user-service\"}) by (hpa)",
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

kubectl apply -f grafana-dashboards.yaml

# Create a ConfigMap for Grafana datasources
echo "Creating Grafana datasources..."
cat > grafana-datasources.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-datasources
  namespace: $NAMESPACE
data:
  prometheus-datasource.yaml: |
    apiVersion: 1
    datasources:
    - name: Prometheus
      type: prometheus
      url: http://prometheus-server.$NAMESPACE.svc.cluster.local
      access: proxy
      isDefault: true
EOF

kubectl apply -f grafana-datasources.yaml

# Install Grafana using Helm
echo "Installing Grafana..."
helm upgrade --install grafana grafana/grafana \
  --namespace $NAMESPACE \
  --set persistence.enabled=true \
  --set persistence.size=2Gi \
  --set dashboardProviders."dashboardproviders\.yaml".apiVersion=1 \
  --set dashboardProviders."dashboardproviders\.yaml".providers[0].name=default \
  --set dashboardProviders."dashboardproviders\.yaml".providers[0].orgId=1 \
  --set dashboardProviders."dashboardproviders\.yaml".providers[0].folder="" \
  --set dashboardProviders."dashboardproviders\.yaml".providers[0].type=file \
  --set dashboardProviders."dashboardproviders\.yaml".providers[0].disableDeletion=false \
  --set dashboardProviders."dashboardproviders\.yaml".providers[0].editable=true \
  --set dashboardProviders."dashboardproviders\.yaml".providers[0].options.path=/var/lib/grafana/dashboards/default \
  --set dashboards.default.frontend-user-service-overview.json="$(cat grafana-dashboards.yaml)" \
  --set datasources."datasources\.yaml".apiVersion=1 \
  --set datasources."datasources\.yaml".datasources[0].name=Prometheus \
  --set datasources."datasources\.yaml".datasources[0].type=prometheus \
  --set datasources."datasources\.yaml".datasources[0].url=http://prometheus-server.$NAMESPACE.svc.cluster.local \
  --set datasources."datasources\.yaml".datasources[0].access=proxy \
  --set datasources."datasources\.yaml".datasources[0].isDefault=true \
  --version $GRAFANA_VERSION

# Clean up temporary files
rm -f prometheus-config.yaml grafana-dashboards.yaml grafana-datasources.yaml

# Wait for deployments to be ready
echo "Waiting for Prometheus to be ready..."
kubectl rollout status deployment/prometheus-server -n $NAMESPACE --timeout=300s

echo "Waiting for Grafana to be ready..."
kubectl rollout status deployment/grafana -n $NAMESPACE --timeout=300s

# Create a script to access Grafana
echo "Creating access script..."
cat > access-grafana.sh << EOF
#!/bin/bash

# Get the Grafana admin password
GRAFANA_PASSWORD=\$(kubectl get secret --namespace $NAMESPACE grafana -o jsonpath="{.data.admin-password}" | base64 --decode)
echo "Grafana admin password: \$GRAFANA_PASSWORD"

# Port forward to access Grafana
echo "Starting port forwarding to Grafana on port 3000..."
echo "Access Grafana at: http://localhost:3000"
echo "Username: admin"
echo "Password: \$GRAFANA_PASSWORD"
echo "Press Ctrl+C to stop port forwarding"
kubectl port-forward --namespace $NAMESPACE svc/grafana 3000:80
EOF

chmod +x access-grafana.sh
mv access-grafana.sh scripts/infrastructure/

# Create a script to access Prometheus
echo "Creating access script for Prometheus..."
cat > access-prometheus.sh << EOF
#!/bin/bash

# Port forward to access Prometheus
echo "Starting port forwarding to Prometheus on port 9090..."
echo "Access Prometheus at: http://localhost:9090"
echo "Press Ctrl+C to stop port forwarding"
kubectl port-forward --namespace $NAMESPACE svc/prometheus-server 9090:80
EOF

chmod +x access-prometheus.sh
mv access-prometheus.sh scripts/infrastructure/

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
echo "  Password: (Retrieved by the access script)"
echo "========================================="

# Add annotations to frontend and user-service deployments for Prometheus scraping
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