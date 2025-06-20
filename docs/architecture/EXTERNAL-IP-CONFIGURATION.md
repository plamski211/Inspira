# External IP Configuration for Inspira Microservices

## Overview

We've configured external IP addresses for key services in the Inspira microservices architecture to provide direct access to these services without going through the ingress controller.

## Implemented Configuration

1. **Created External Service Definitions**:
   - Created `k8s-public/external-services.yaml` with LoadBalancer service definitions for:
     - API Gateway
     - Frontend
     - MinIO

2. **Applied the Configuration**:
   - Applied the external services configuration to the Kubernetes cluster
   - Verified that external IPs are being assigned

3. **Created Utility Scripts**:
   - `get-external-ips.sh`: Script to check the status of external IP assignments
   - `update-dns-records.sh`: Script to update DNS records with the external IPs

4. **Updated Documentation**:
   - Added external services information to `DEPLOYMENT-GUIDE.md`
   - Created `EXTERNAL-SERVICES.md` with detailed information
   - Updated `DEPLOYMENT-SUCCESS.md` with current status

5. **Updated CI/CD Pipeline**:
   - Added external services deployment to the GitHub Actions workflow

## Current Status

As of the latest check:

- **Ingress Controller**: 4.156.37.48 (assigned)
- **API Gateway External**: 20.242.229.250 (assigned)
- **Frontend External**: (pending assignment)
- **MinIO External**: (pending assignment)

Azure is still in the process of assigning external IPs to some services. This can take some time depending on resource availability in the region.

## Next Steps

1. **Monitor External IP Assignment**:
   - Continue to run `./get-external-ips.sh` to check for newly assigned IPs
   - Once all IPs are assigned, update documentation with the final values

2. **Configure DNS Records**:
   - Once all IPs are assigned, run `./update-dns-records.sh` to configure DNS records
   - This will map domain names to the external IPs for easier access

3. **Update Application Configuration**:
   - Update any application configuration that needs to reference these external services
   - Ensure services are configured to use the appropriate endpoints

4. **Test External Access**:
   - Verify that all services are accessible via their external IPs
   - Test both HTTP and HTTPS access where applicable

## Troubleshooting

If external IPs remain in a pending state for an extended period, consider the following:

1. **Check Azure Quota Limits**:
   - Ensure your Azure subscription has sufficient quota for public IP addresses
   - Request quota increases if necessary

2. **Check Network Security Groups**:
   - Verify that network security groups allow traffic to the required ports
   - Update rules if necessary

3. **Check Azure Load Balancer Configuration**:
   - Verify that the Azure Load Balancer is properly configured
   - Check for any error messages in the Azure portal

4. **Contact Azure Support**:
   - If issues persist, contact Azure support for assistance 