#!/bin/bash

set -e

REPO_ROOT="$(git rev-parse --show-toplevel)"
SCRIPT_DIR="$REPO_ROOT/scripts"
source "${SCRIPT_DIR}/common.sh"

check_do_token

REGISTRY_NAME=$(cd tofu && $TERRAFORM output -raw registry_name)

# Create registry secret
echo "Creating registry credentials in cluster..."
doctl registry kubernetes-manifest | kubectl apply -f -

# Patch service account
echo "Patching default service account..."
kubectl patch serviceaccount default -n demo -p "{\"imagePullSecrets\": [{\"name\": \"registry-${REGISTRY_NAME}\"}]}"

echo "Registry authentication configured successfully"
