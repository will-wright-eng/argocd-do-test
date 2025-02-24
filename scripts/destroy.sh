#!/bin/bash

set -e

REPO_ROOT="$(git rev-parse --show-toplevel)"
SCRIPT_DIR="$REPO_ROOT/scripts"
source "${SCRIPT_DIR}/common.sh"

check_do_token

# Check for tofu directory
if [ ! -d "$TERRAFORM" ]; then
    echo "Error: tofu directory not found"
    echo "Please run this script from the project root directory"
    exit 1
fi

# Navigate to tofu directory
cd $TERRAFORM

# Get cluster name and region from terraform output (before destroy)
CLUSTER_NAME=$($TERRAFORM output -raw cluster_name)
REGION=$($TERRAFORM output -raw region)
CONTEXT_NAME="do_${REGION}_${CLUSTER_NAME}"

# Run tofu destroy with plan
echo "Planning destruction of infrastructure..."
$TERRAFORM plan -destroy -out=tfplan

# Prompt for confirmation with warning
echo "WARNING: This will destroy all resources managed by tofu!"
echo "This action cannot be undone."
read -p "Are you absolutely sure you want to destroy all resources? (yes/no) " -r
echo
if [[ $REPLY =~ ^yes$ ]]; then
    # Apply destruction
    echo "Destroying infrastructure..."
    $TERRAFORM apply tfplan

    # Clean up kubeconfig if destroy was successful
    if [ $? -eq 0 ]; then
        if kubectl config get-contexts "${CONTEXT_NAME}" &>/dev/null; then
            echo "Cleaning up kubeconfig..."

            # Remove the context and cluster from the config
            kubectl config delete-context "${CONTEXT_NAME}"
            kubectl config delete-cluster "${CONTEXT_NAME}"
            kubectl config unset "users.${CONTEXT_NAME}"

            echo "Removed cluster context '${CONTEXT_NAME}' from kubeconfig"
        fi
    fi
else
    echo "Destroy cancelled"
    rm tfplan
    exit 0
fi

# Clean up plan file
rm tfplan
