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
        if [ -f ~/.kube/config-do-demo ]; then
            echo "Cleaning up kubeconfig..."
            rm ~/.kube/config-do-demo
            echo "Removed ~/.kube/config-do-demo"

            # Check if the active config is our symlink
            if [ -L ~/.kube/config ] && [ "$(readlink ~/.kube/config)" = "$HOME/.kube/config-do-demo" ]; then
                rm ~/.kube/config
                echo "Removed symlink from ~/.kube/config"
            fi
        fi
    fi
else
    echo "Destroy cancelled"
    rm tfplan
    exit 0
fi

# Clean up plan file
rm tfplan
