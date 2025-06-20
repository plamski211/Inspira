# External Services Configuration

This document provides information about the external services configured for the Inspira microservices architecture.

## Overview

In addition to the ingress controller that routes traffic to all services, we've configured dedicated external LoadBalancer services for direct access to key components:

1. **API Gateway External**: Direct access to the API Gateway
2. **Frontend External**: Direct access to the frontend application
3. **MinIO External**: Direct access to MinIO storage API and console

## Current External IPs

As of the latest deployment:

- **Ingress Controller**: 4.156.37.48
- **API Gateway External**: 20.242.229.250
- **Frontend External**: (pending assignment)
- **MinIO External**: (pending assignment)

To get the latest external IPs, run:

```bash
./get-external-ips.sh
```

## Access URLs

### Via Ingress Controller

All services are accessible through the Ingress controller at the following paths:

- Frontend: http://4.156.37.48/ or https://4.156.37.48/
- API Gateway: http://4.156.37.48/api/gateway/ or https://4.156.37.48/api/gateway/
- User Service: http://4.156.37.48/api/users/ or https://4.156.37.48/api/users/
- Content Service: http://4.156.37.48/api/content/ or https://4.156.37.48/api/content/
- Media Service: http://4.156.37.48/api/media/ or https://4.156.37.48/api/media/

### Via External Services

- **API Gateway**: 
  - HTTP: http://20.242.229.250/
  - HTTPS: https://20.242.229.250/

- **Frontend**: (pending IP assignment)
  - HTTP: http://{FRONTEND_IP}/
  - HTTPS: https://{FRONTEND_IP}/

- **MinIO**: (pending IP assignment)
  - API: http://{MINIO_IP}:9000/
  - Console: http://{MINIO_IP}:9001/

## Configuration Details

The external services are defined in `k8s-public/external-services.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: api-gateway-external
  namespace: microservices
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-internal: "false"
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 80
    name: http
  - port: 443
    targetPort: 80
    name: https
  selector:
    app: api-gateway
```

## Benefits of External Services

1. **Direct Access**: Bypasses the ingress controller for direct access to services
2. **Dedicated IPs**: Each service has its own dedicated IP address
3. **Specialized Ports**: Allows exposing non-HTTP ports (e.g., MinIO's 9000 and 9001 ports)
4. **Load Distribution**: Distributes traffic across multiple load balancers

## Maintenance

To update external service configurations:

1. Edit the `k8s-public/external-services.yaml` file
2. Apply the changes:

```bash
kubectl apply -f k8s-public/external-services.yaml
```

3. Check the new IP assignments:

```bash
./get-external-ips.sh
``` 