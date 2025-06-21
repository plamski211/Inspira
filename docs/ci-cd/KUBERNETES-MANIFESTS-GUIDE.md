# Kubernetes Manifests Guide

This document provides guidance on managing, validating, and troubleshooting Kubernetes manifests in the Inspira CI/CD pipeline.

## Manifest Structure

The Inspira project uses a structured approach to Kubernetes manifests:

- `k8s/base/` - Contains base manifests for all services
- `k8s/overlays/` - Contains environment-specific overlays (dev, prod, azure)
- `k8s-azure/` - Contains generated manifests for Azure deployment

## Manifest Validation

The CI/CD pipeline validates all Kubernetes manifests using `kubeval` to ensure they conform to Kubernetes schema definitions.

### Running Validation Locally

To validate manifests locally:

```bash
./scripts/ci-cd/validate-k8s-manifests.sh
```

This script will:
1. Install `kubeval` if not already installed
2. Validate all manifests in `k8s/base/` and `k8s-azure/`
3. Generate manifests if needed using `prepare-k8s-manifests.sh`

### Common Validation Errors

| Error | Description | Solution |
|-------|-------------|----------|
| `Additional property X is not allowed` | Unknown field in manifest | Remove the field or update kubeval version |
| `Invalid type. Expected: [array], given: string` | Incorrect data type | Fix the data type in the manifest |
| `Missing required property` | Required field is missing | Add the required field |
| `Invalid Kubernetes version` | Schema version mismatch | Specify correct version with `--kubernetes-version` |

## Manifest Generation

The pipeline automatically generates manifests for Azure deployment using the `prepare-k8s-manifests.sh` script. This script:

1. Creates the `k8s-azure` directory if it doesn't exist
2. Copies base manifests from `k8s/base`
3. Applies Azure-specific overlays from `k8s/overlays/azure`
4. Applies any necessary patches

### Manual Manifest Generation

To generate manifests manually:

```bash
./scripts/ci-cd/prepare-k8s-manifests.sh
```

## Troubleshooting

### Missing Manifests

If the pipeline fails with "manifest not found" errors:

1. Check that the `k8s/base` directory contains all required manifests
2. Verify that `prepare-k8s-manifests.sh` is generating the expected files
3. Run `./scripts/ci-cd/validate-k8s-manifests.sh` to validate and generate manifests

### Invalid Manifests

If the pipeline fails with "invalid manifest" errors:

1. Run `./scripts/ci-cd/validate-k8s-manifests.sh` to identify specific issues
2. Fix the reported errors in the manifest files
3. Re-run validation to confirm fixes

### Resource Quotas

If deployments fail due to resource constraints:

1. Check `k8s/base/resource-quota.yaml` for current limits
2. Adjust resource requests/limits in deployment manifests
3. Consider using Horizontal Pod Autoscaler for dynamic scaling

## Best Practices

1. **Use Base/Overlay Structure**: Keep common configurations in base and environment-specific changes in overlays
2. **Validate Before Committing**: Run validation locally before pushing changes
3. **Include Resource Limits**: Always specify resource requests and limits
4. **Use ConfigMaps**: Externalize configuration using ConfigMaps
5. **Set Liveness/Readiness Probes**: Include health checks for all services
6. **Use Labels Consistently**: Apply consistent labeling for all resources
7. **Document Changes**: Add comments for non-obvious configurations

## Reference

- [Kubernetes API Reference](https://kubernetes.io/docs/reference/kubernetes-api/)
- [Kubeval Documentation](https://www.kubeval.com/docs/)
- [Kustomize Documentation](https://kubectl.docs.kubernetes.io/guides/introduction/kustomize/) 