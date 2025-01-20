#!/bin/bash

set -e

REPO_ROOT="$(git rev-parse --show-toplevel)"
SCRIPT_DIR="$REPO_ROOT/devops/k8s/argocd/scripts"
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
        mkdir -p ~/.kube
        $TERRAFORM output -raw kubeconfig > ~/.kube/config-do-demo
        echo "Kubeconfig exported to ~/.kube/config-do-demo"

        # Create symbolic link to make it the active config
        read -p "Make this your active kubeconfig? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ln -sf ~/.kube/config-do-demo ~/.kube/config
            echo "Kubeconfig symlinked to ~/.kube/config"
        fi
    fi
else
    echo "Apply cancelled"
    rm tfplan
    exit 0
fi

# Clean up plan file
rm tfplan
