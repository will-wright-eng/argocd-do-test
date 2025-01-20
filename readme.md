# ArgoCD Deployment on DigitalOcean

This project demonstrates a GitOps approach to deploying applications on DigitalOcean Kubernetes using ArgoCD. It includes infrastructure as code using OpenTofu, Kubernetes manifests, and a sample Python API application.

## Prerequisites

- DigitalOcean account with API token
- `doctl` CLI tool installed and configured
- `kubectl` installed
- OpenTofu installed
- Docker installed
- Access to a DigitalOcean Container Registry

## Getting Started

1. Initialize the project:

```bash
make init
```

2. Configure your DigitalOcean credentials:

```bash
export DO_TOKEN="your-digitalocean-token"
```

3. Deploy the infrastructure:

```bash
make apply
```

4. Verify cluster connectivity:

```bash
make verify
```

5. Set up container registry:

```bash
make registry-auth
make registry-login
```

## Deploying Applications

1. Install ArgoCD:

```bash
make argo-install
```

2. Access ArgoCD UI:

```bash
make argo-pf
```

Access the UI at <http://localhost:8080>

3. Get the admin password:

```bash
make argo-pass
```

4. Apply ArgoCD configurations:

```bash
make argo-apply
```

## Local Development

1. Run the API locally:

```bash
make local
```

2. Check API health:

```bash
make health
```

3. Stop local environment:

```bash
make kill
```

## Cleanup

To destroy all resources and clean up:

```bash
make destroy
make cleanup
```

## Project Structure

```
.
├── api/                    # Sample Python API application
├── argocd/                # ArgoCD configuration
│   ├── applications/      # ArgoCD application manifests
│   └── projects/         # ArgoCD project definitions
├── k8s/                   # Kubernetes manifests
│   ├── base/             # Base Kustomize configuration
│   └── overlays/         # Environment-specific overlays
├── scripts/              # Utility scripts
└── tofu/                # Infrastructure as code (OpenTofu)
```

## Architecture

This project uses:

- ArgoCD for GitOps-based deployments
- Kustomize for Kubernetes manifest management
- OpenTofu for infrastructure provisioning
- Python FastAPI for the sample application
- DigitalOcean Kubernetes for container orchestration
- DigitalOcean Container Registry for image storage

## Environment Variables

```bash
ENV ?= dev                 # Environment (default: dev)
API_PORT ?= 8080          # Local API port
DOCKER_TAG ?= latest      # Docker image tag
```

## Available Commands

### Infrastructure Management

```bash
make init        # Initialize OpenTofu configuration
make apply      # Apply OpenTofu infrastructure changes
make destroy    # Destroy OpenTofu-managed infrastructure
make cleanup    # Remove generated files and OpenTofu artifacts
```

### Docker Operations

```bash
make docker-build    # Build Docker image
make docker-push     # Push Docker image to registry
make local          # Test API locally using Docker Compose
make kill           # Stop local Docker containers
make health         # Check API health status
```

### Kubernetes Operations

```bash
make verify         # Verify cluster connectivity
make cluster-info   # Display cluster information and status
```

### ArgoCD Management

```bash
make argo-install   # Install ArgoCD in the cluster
make argo-pass      # Get ArgoCD admin password
make argo-pf        # Port forward ArgoCD UI to localhost:8080
make argo-apply     # Apply ArgoCD configuration
```

### Registry Management

```bash
make registry-login  # Login to DigitalOcean container registry
make registry-auth   # Configure registry authentication
```

### Kubernetes Operations

```bash
make delete-pods     # Delete all pods in the demo namespace
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## Troubleshooting

### Common Issues

1. If ArgoCD UI is not accessible:
   - Check if pods are running: `kubectl get pods -n argocd`
   - Verify port forwarding: `make argo-pf`

2. If Docker push fails:
   - Verify registry authentication: `make registry-auth`
   - Re-login to registry: `make registry-login`

3. If cluster verification fails:
   - Check DO_TOKEN environment variable
   - Verify cluster status in DigitalOcean console
   - Run `make cluster-info` for detailed status
