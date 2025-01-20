#!/bin/bash
# verify-cluster.sh - Script to verify Kubernetes cluster setup

# Exit on any error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1${NC}"
    else
        echo -e "${RED}✗ $1${NC}"
        exit 1
    fi
}

echo -e "${YELLOW}Starting Kubernetes cluster verification...${NC}"

# 1. Check kubectl access
echo "Checking kubectl access..."
kubectl cluster-info > /dev/null 2>&1
print_status "Kubectl can connect to cluster"

# 2. Check nodes status
echo "Checking node status..."
NODES_READY=$(kubectl get nodes -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}' | grep -o "True" | wc -l)
TOTAL_NODES=$(kubectl get nodes --no-headers | wc -l)

if [ "$NODES_READY" -eq "$TOTAL_NODES" ]; then
    echo -e "${GREEN}✓ All nodes are ready ($NODES_READY/$TOTAL_NODES)${NC}"
else
    echo -e "${RED}✗ Not all nodes are ready ($NODES_READY/$TOTAL_NODES)${NC}"
    echo "Node details:"
    kubectl get nodes
    exit 1
fi

# 3. Check core components
echo "Checking core components..."
kubectl get pods -n kube-system --no-headers | while read line; do
    if [[ $(echo $line | awk '{print $3}') != "Running" ]]; then
        echo -e "${RED}✗ Pod not running: $line${NC}"
        exit 1
    fi
done
print_status "All core components are running"

# 4. Check API access
echo "Checking API access..."
kubectl auth can-i create pods > /dev/null 2>&1
print_status "API authorization check passed"

# 5. Check default storage class
echo "Checking storage class..."
if kubectl get storageclass | grep -q "(default)"; then
    print_status "Default storage class exists"
else
    echo -e "${YELLOW}! No default storage class found - this might be needed for persistent volumes${NC}"
fi

# 6. Check network connectivity
echo "Checking network connectivity..."
cat <<EOF | kubectl apply -f - > /dev/null 2>&1
apiVersion: v1
kind: Pod
metadata:
  name: test-network
  labels:
    app: test-network
spec:
  containers:
  - name: nginx
    image: nginx:alpine
EOF

echo "Waiting for test pod to be ready..."
kubectl wait --for=condition=ready pod -l app=test-network --timeout=60s > /dev/null 2>&1
print_status "Network test pod created successfully"

# Cleanup test pod
kubectl delete pod test-network > /dev/null 2>&1

# 7. Print cluster info
echo -e "\n${YELLOW}Cluster Information:${NC}"
echo "------------------------"
kubectl cluster-info
echo -e "\n${YELLOW}Node Resources:${NC}"
echo "------------------------"
kubectl top nodes 2>/dev/null || echo -e "${YELLOW}Metrics server not available${NC}"

echo -e "\n${GREEN}Verification complete!${NC}"
