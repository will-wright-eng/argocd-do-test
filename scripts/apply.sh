#!/bin/bash

set -e

REPO_ROOT="$(git rev-parse --show-toplevel)"
SCRIPT_DIR="$REPO_ROOT/scripts"
source "${SCRIPT_DIR}/common.sh"

check_do_token

# Create tofu directory if it doesn't exist
if [ ! -d "$TERRAFORM" ]; then
    echo "Error: $TERRAFORM directory not found"
    echo "Please run this script from the project root directory"
    exit 1
fi

# Navigate to tofu directory
cd $TERRAFORM

# Initialize tofu if not already initialized
if [ ! -d ".terraform" ]; then
    echo "Initializing tofu..."
    $TERRAFORM init
fi

# Run tofu plan
echo "Running tofu plan..."
$TERRAFORM plan -out=tfplan

# Prompt for confirmation
read -p "Do you want to apply this plan? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Apply tofu configuration
    echo "Applying tofu configuration..."
    $TERRAFORM apply tfplan

    # Export kubeconfig if apply was successful
    if [ $? -eq 0 ]; then
        echo "Exporting kubeconfig..."
        
        # Get cluster name and region from terraform output
        CLUSTER_NAME=$($TERRAFORM output -raw cluster_name)
        REGION=$($TERRAFORM output -raw region)
        CONTEXT_NAME="do_${REGION}_${CLUSTER_NAME}"
        
        # Export to a temporary file
        mkdir -p ~/.kube
        $TERRAFORM output -raw kubeconfig > ~/.kube/config-temp
        
        # Rename the context to our standardized name
        kubectl --kubeconfig ~/.kube/config-temp config rename-context "do-k8s" "${CONTEXT_NAME}"
        
        # Merge the new kubeconfig with existing config
        read -p "Add/Update this cluster in your kubeconfig? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            KUBECONFIG=~/.kube/config:~/.kube/config-temp kubectl config view --flatten > ~/.kube/config.tmp
            mv ~/.kube/config.tmp ~/.kube/config
            rm ~/.kube/config-temp
            echo "Kubeconfig merged successfully"
            echo "Cluster context name: ${CONTEXT_NAME}"
            echo "You can switch to this cluster using: kubectx ${CONTEXT_NAME}"
        fi
    fi
else
    echo "Apply cancelled"
    rm tfplan
    exit 0
fi

# Clean up plan file
rm tfplan
