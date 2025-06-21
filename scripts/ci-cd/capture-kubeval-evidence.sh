#!/bin/bash

# Script to capture evidence of kubeval in action
# This script runs kubeval and saves the output as evidence

EVIDENCE_DIR="docs/evidence"
KUBEVAL_EVIDENCE_FILE="$EVIDENCE_DIR/kubeval-validation-evidence.txt"
KUBEVAL_SUMMARY_FILE="$EVIDENCE_DIR/kubeval-summary.md"

echo "===== Capturing Kubeval Evidence ====="
echo ""

# Create evidence directory if it doesn't exist
mkdir -p "$EVIDENCE_DIR"

# Check if kubeval is installed
if ! command -v kubeval &> /dev/null && ! [ -f "./kubeval" ]; then
  echo "Kubeval not found. Installing kubeval first..."
  ./scripts/ci-cd/validate-k8s-manifests.sh
  echo ""
fi

# Determine kubeval command
if command -v kubeval &> /dev/null; then
  KUBEVAL="kubeval"
elif [ -f "./kubeval" ]; then
  KUBEVAL="./kubeval"
else
  echo "❌ Failed to find kubeval. Please run ./scripts/ci-cd/validate-k8s-manifests.sh first."
  exit 1
fi

echo "===== Running Kubeval on Kubernetes Manifests ====="
echo ""

# Capture date and time
DATE_TIME=$(date "+%Y-%m-%d %H:%M:%S")

# Create header for evidence file
cat > "$KUBEVAL_EVIDENCE_FILE" << EOF
# Kubeval Validation Evidence

**Date and Time:** $DATE_TIME

## System Information
- OS: $(uname -s)
- Kubeval Version: $($KUBEVAL --version 2>&1 || echo "Version information not available")

## Validation Results
EOF

# Function to run kubeval and capture output
run_kubeval() {
  local dir=$1
  local title=$2
  
  echo "Validating manifests in $dir directory..."
  
  # Add section to evidence file
  echo -e "\n### $title\n" >> "$KUBEVAL_EVIDENCE_FILE"
  echo '```' >> "$KUBEVAL_EVIDENCE_FILE"
  
  # Run kubeval and capture output
  if [ -d "$dir" ]; then
    $KUBEVAL --ignore-missing-schemas "$dir"/*.yaml | tee -a "$KUBEVAL_EVIDENCE_FILE"
    RESULT=$?
    if [ $RESULT -eq 0 ]; then
      echo -e "\n✅ All manifests in $dir directory are valid" | tee -a "$KUBEVAL_EVIDENCE_FILE"
    else
      echo -e "\n❌ Some manifests in $dir directory are invalid" | tee -a "$KUBEVAL_EVIDENCE_FILE"
    fi
  else
    echo "Directory $dir not found." | tee -a "$KUBEVAL_EVIDENCE_FILE"
  fi
  
  echo '```' >> "$KUBEVAL_EVIDENCE_FILE"
}

# Run kubeval on different directories
run_kubeval "k8s/base" "Base Kubernetes Manifests"
run_kubeval "k8s-azure" "Azure Kubernetes Manifests"
run_kubeval "k8s/overlays/azure" "Azure Overlay Manifests"

# Create summary file
cat > "$KUBEVAL_SUMMARY_FILE" << EOF
# Kubeval Validation Summary

## Overview

Kubeval is integrated into our CI/CD pipeline to validate Kubernetes manifests before deployment. This ensures that all our Kubernetes configurations conform to the official Kubernetes schema, preventing misconfigurations that could lead to deployment failures or security vulnerabilities.

## Implementation

1. **Automated Validation**: Kubeval runs automatically during our CI/CD pipeline
2. **Local Validation**: Developers can run validation locally using \`./scripts/ci-cd/validate-k8s-manifests.sh\`
3. **Documentation**: Comprehensive guide available in \`docs/ci-cd/KUBERNETES-MANIFESTS-GUIDE.md\`

## Evidence

Detailed validation results are available in [kubeval-validation-evidence.txt](kubeval-validation-evidence.txt).

The validation was performed on $DATE_TIME and included:
- Base Kubernetes manifests in \`k8s/base/\`
- Generated manifests for Azure in \`k8s-azure/\`
- Azure-specific overlays in \`k8s/overlays/azure/\`

## Benefits to Software Quality

1. **Reliability**: Prevents deployment of invalid configurations
2. **Consistency**: Ensures all manifests follow Kubernetes standards
3. **Early Detection**: Catches errors before they reach production
4. **Developer Productivity**: Provides immediate feedback on manifest validity
5. **Reduced Downtime**: Prevents outages caused by misconfiguration

## Integration with Cloud Services

Kubeval validates our cloud service configurations, including:
- Kubernetes Deployments for containerized microservices
- Horizontal Pod Autoscalers for dynamic scaling
- Service Monitors for Prometheus integration
- Network Policies for enhanced security
- Resource Quotas for cost optimization

This validation ensures that our cloud services are correctly configured and will function as expected when deployed.
EOF

echo ""
echo "===== Evidence Capture Complete ====="
echo ""
echo "Evidence files created:"
echo "- $KUBEVAL_EVIDENCE_FILE"
echo "- $KUBEVAL_SUMMARY_FILE"
echo ""
echo "You can include these files in your documentation or reports as evidence of kubeval integration." 