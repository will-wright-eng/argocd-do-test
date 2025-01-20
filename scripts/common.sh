#!/bin/bash

TERRAFORM="tofu"
REPO_ROOT="$(git rev-parse --show-toplevel)"
SCRIPT_DIR="$REPO_ROOT/devops/k8s/argocd/scripts"

# Check if DO_TOKEN is provided
check_do_token() {
    if [ -z "$DO_TOKEN" ]; then
        echo "Error: DO_TOKEN environment variable is not set"
        echo "Usage: DO_TOKEN=your_token ./script.sh"
        exit 1
    fi
    # Export DO_TOKEN as a tofu variable
    export TF_VAR_do_token="$DO_TOKEN"
}
